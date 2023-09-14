require "stumpy_png"
include StumpyPNG

require "compress/gzip"
require "compress/zlib"
require "string_pool"
require "crustache"
require "option_parser"

require "./version"
require "./tag"
require "./reader"
require "./writer"
require "./xml_parser"
require "./region"
require "./chunk"
require "./map_colors"

BUILD_HEIGHT  = 384
DEFAULT_COLOR = Color(UInt8).new(BUILD_HEIGHT // 2, BUILD_HEIGHT // 2, BUILD_HEIGHT // 2)
MC_REGEX      = /^minecraft\:/i

struct Options
  setter output_path : String?
  setter colors_path : String?
  setter biomes_path : String?
  setter template_path : String?
  property show_missing_blocks : Bool = false
  property show_missing_biomes : Bool = false
  property biomes_only : Bool = false
  property shading : Bool = true

  @world_name : String?

  def input_path
    ARGV[0]?.not_nil!
  rescue e : NilAssertionError
    STDERR.puts "World path is required (see -h)"
    exit(1)
  end

  def world_name
    return @world_name.not_nil! if @world_name

    match_data = /saves\/([^\/]+)/i.match(input_path).not_nil!
    @world_name = match_data[1]
  end

  def output_path
    @output_path || world_name
  end

  def block_colors_path
    @colors_path || "block_colors.yaml"
  end

  def biome_colors_path
    @biomes_path || "biome_colors.yaml"
  end

  def template_path
    @template_path || "map_template.html"
  end
end

options = Options.new

OptionParser.parse do |parser|
  parser.banner = "Usage: nbtmap <world_path> [options]"

  parser.on("-v", "--version", "Show version") { puts Nbt::VERSION; exit }
  parser.on("-h", "--help", "Show help") { puts parser; exit }
  parser.on("-o", "--output=PATH", "Output path") { |path| options.output_path = path }

  parser.on("--colors=PATH", "Path to json file containing color definitions for blocks") do |path|
    options.colors_path = path
  end

  parser.on("--biomes=PATH", "Path to json file containing color definitions for biomes") do |path|
    options.biomes_path = path
  end

  parser.on("--template=PATH", "Path to the mustache html template to render") do |path|
    options.template_path = path
  end

  parser.on("--show-missing-blocks", "Lists blocks that are missing from block_colors.json") do
    options.show_missing_blocks = true
  end

  parser.on("--show-missing-biomes", "Lists biomes that are missing from biome_colors.json") do
    options.show_missing_biomes = true
  end

  parser.on("--biomes-only", "Only show biome colors") { options.biomes_only = true }
  parser.on("--no-shading", "Don't shade based on height") { options.shading = false }
end

pool = StringPool.new

begin
  block_colors = MapColors.new(options.block_colors_path)
  biome_colors = MapColors.new(options.biome_colors_path)
rescue e : YAML::ParseException
  STDERR.puts "Cannot parse a colors json file:"
  STDERR.puts e
  exit(1)
end

Dir.mkdir_p(options.output_path)
image_tags = Array(String).new

missing_blocks = Set(String).new
missing_biomes = Set(String).new

alias RegionData = Int32 | String | Array(String) | Array(Hash(String, String | Int32))

render_data = {
  "world_name" => options.world_name,
  "regions"    => [] of Hash(String, RegionData),
}

structures = {} of String => Nbt::Chunk::Coords

Dir.glob("#{options.input_path}/region/r.*.*.mca").each do |path|
  next unless File.exists?(path)
  next if File.size(path) == 0

  match_data = /r\.(-?\d+)\.(-?\d+)/.match(File.basename(path, ".mca")).not_nil!
  rx = match_data[1].to_i
  rz = match_data[2].to_i

  file = File.open(path, "rb")
  region = Nbt::Region.new(file)

  canvas = Canvas.new(16 * 32, 16 * 32)

  region_data = {
    "x"          => rx,
    "z"          => rz,
    "structures" => [] of Hash(String, String | Int32),
  } of String => RegionData
  biomes = Set(String).new

  no_chunks = true

  0.upto(31) do |cx|
    0.upto(31) do |cz|
      next unless chunk_tag = region.read_chunk(cx, cz)

      chunk = Nbt::Chunk.new(chunk_tag)

      chunk.structures.each do |name, coords|
        structures[name] ||= Set(Tuple(Int32, Int32)).new
        structures[name] |= coords
      end

      if floor = chunk.ocean_floor
        if surface = chunk.world_surface
          0.upto(15) do |z|
            0.upto(15) do |x|
              surface_y = surface[z * 16 + x] - 1
              floor_y = floor[z * 16 + x] - 1

              if palette_tag = chunk.block(x: x, y: floor_y, z: z)
                no_chunks = false

                biome = chunk.biome(x, floor_y, z).not_nil!.payload.as(String).gsub(MC_REGEX, "")
                block = palette_tag["Name"]?.not_nil!.as(Nbt::Tag).payload.not_nil!.as(String).gsub(MC_REGEX, "")

                biomes << biome

                unless options.biomes_only
                  color = block_colors[block]? || DEFAULT_COLOR
                else
                  color = DEFAULT_COLOR
                end

                if options.shading
                  brightness = floor_y / (BUILD_HEIGHT / 2)
                  color = color * brightness
                end

                color = RGBA.from_rgba_n(color.r, color.g, color.b, color.a, 8)

                # Add water
                if floor_y != surface_y
                  if tag = chunk.block(x: x, y: surface_y, z: z)
                    surface_block = tag["Name"]?.not_nil!.as(Nbt::Tag).payload.not_nil!.as(String).gsub(MC_REGEX, "")

                    if c2 = block_colors[surface_block]?
                      if options.shading
                        brightness = surface_y / (BUILD_HEIGHT / 2)
                        c2 *= brightness
                      end

                      color = RGBA.from_rgba_n(c2.r, c2.g, c2.b, c2.a, 8).over(color)
                    end
                  end
                end

                if tint = biome_colors[biome]?
                  color = RGBA.from_rgba_n(tint.r, tint.g, tint.b, tint.a, 8).over(color)
                end

                canvas[cx * 16 + x, cz * 16 + z] = color
              else
                color = DEFAULT_COLOR

                if options.shading
                  brightness = floor_y / (BUILD_HEIGHT / 2)
                  color = color * brightness
                end

                color = RGBA.from_rgba_n(color.r, color.g, color.b, color.a, 8)
                canvas[cx * 16 + x, cz * 16 + z] = color
              end
            end
          end
        end
      end
    end
  end

  next if no_chunks

  file.close
  img_path = "r.#{rx}.#{rz}.png"

  puts "Region: #{rx},#{rz}"

  region_data["biomes"] = biomes.to_a.map(&.gsub(MC_REGEX, ""))
  render_data["regions"].as(Array(Hash(String, RegionData))) << region_data

  StumpyPNG.write(canvas, "#{options.output_path}/#{img_path}", bit_depth: 8)
end

if options.show_missing_blocks && block_colors.missing.any?
  STDERR.puts "Missing blocks:"
  STDERR.puts block_colors.missing.join("\n")
end

if options.show_missing_biomes && biome_colors.missing.any?
  STDERR.puts "Missing biomes:"
  STDERR.puts biome_colors.missing.join("\n")
end

structures.each do |name, coords|
  coords.each do |xz|
    x, z = xz # Absolute chunk coords
    rx, rz = x // 32, z // 32
    cx, cz = x % 32, z % 32

    if region_data = render_data["regions"].as(Array(Hash(String, RegionData))).find { |r| r["x"] == rx && r["z"] == rz }
      region_data["structures"].as(Array(Hash(String, String | Int32))) << {
        "name"  => name.gsub(MC_REGEX, ""),
        "x"     => cx,
        "z"     => cz,
        "rel_x" => ((cx / 32) * 100).to_i32,
        "rel_z" => ((cz / 32) * 100).to_i32,
      }
    end
  end
end

template = Crustache.parse(File.read(options.template_path))
File.write("#{options.output_path}/index.html", Crustache.render(template, render_data))
