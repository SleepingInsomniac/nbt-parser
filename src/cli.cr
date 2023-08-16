require "option_parser"
require "compress/gzip"
require "compress/zlib"
require "xml"

require "./version"
require "./tag"
require "./reader"
require "./writer"
require "./xml_parser"
require "./region"

# Check the first 2 bytes for the gzip signature
#
def gzipped?(io : IO) : Bool
  signature_bytes = Bytes.new(2)
  io.read_fully(signature_bytes)
  io.rewind
  signature_bytes[0] == 0x1F_u8 && signature_bytes[1] == 0x8B_u8
end

struct Options
  property input : String?
  property output : String?
  property format : String?
  property uncompress : Bool?
  property compress : Bool = true
  property chunk : String?
end

options = Options.new

OptionParser.parse do |parser|
  parser.banner = "Usage: nbt -f <path> [options]"

  parser.on("-v", "--version", "Show version") { puts Nbt::VERSION; exit }
  parser.on("-h", "--help", "Show help") { puts parser; exit }
  parser.on("-i", "--input=PATH", "Path to an nbt file") { |path| options.input = path }
  parser.on("-o", "--output=PATH", "Output path") { |path| options.output = path }
  parser.on("-f", "--format=FORMAT", "xml,{dat,nbt}") { |format| options.format = format.downcase }
  parser.on("--no-uncompress", "Skip decompression (for input)") { options.uncompress = false }
  parser.on("--no-compress", "Skip compression (for output)") { options.compress = false }
  parser.on("--chunk=CHUNK", "specify chunk for region files: x,z") { |chunk| options.chunk = chunk }
end

# Validations
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

unless file_path = options.input
  STDERR.puts "Input is required, see --help"
  exit(1)
end

unless File.exists?(file_path)
  STDERR.puts "Input file does not exist"
  exit(1)
end

# Reading
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

nbt_data =
  case File.extname(file_path).downcase
  when ".dat", ".nbt"
    file = File.open(file_path, "rb")

    uncompress =
      if options.uncompress.nil?
        gzipped?(file)
      else
        options.uncompress.not_nil!
      end

    root_tag =
      if uncompress
        Compress::Gzip::Reader.open(file) do |gzip|
          Nbt::Reader.new(gzip).parse_tag
        end
      else
        Nbt::Reader.new(file).parse_tag
      end

    file.close
    root_tag
  when ".mca", ".mcr"
    x = 0
    z = 0

    if options.chunk
      chunk_nums = options.chunk.not_nil!.split(/\D+/).map(&.to_i)
      x = chunk_nums[0]
      z = chunk_nums[1]
    end

    file = File.open(file_path, "rb")
    region = Nbt::Region.new(file)

    if root_tag = region.read_chunk(x, z)
      root_tag
    else
      STDERR.puts "Chunk(#{x}, #{z}) is nil"
      exit(2)
    end
  when ".xml"
    file = File.open(file_path, "r")
    root_tag = Nbt::XmlParser.new(file).parse
    file.close
    root_tag
  else
    STDERR.puts "Unknown input file type"
    exit(1)
  end

# Output
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if output_path = options.output
  options.format ||= File.extname(output_path).downcase[1..]
else
  options.format ||=
    case File.extname(file_path).downcase[1..]
    when "xml" then "dat"
    when "dat" then "xml"
    else            "xml"
    end
end

output_io =
  if output_path = options.output
    if options.format == "xml"
      File.open(output_path, "w")
    else
      File.open(output_path, "wb")
    end
  else
    STDOUT
  end

case options.format
when "xml"
  xml = XML.build(indent: 2) do |xml|
    Nbt::Writer.write_xml(nbt_data, xml)
  end

  output_io.puts(xml)
when "dat", "nbt"
  if options.compress
    Compress::Gzip::Writer.open(output_io) do |gzip|
      Nbt::Writer.write(gzip, nbt_data)
    end
  else
    Nbt::Writer.write(output_io, nbt_data)
  end
end

output_io.close
