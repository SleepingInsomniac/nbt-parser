require "option_parser"
require "compress/gzip"
require "xml"

require "./version"
require "./tag"
require "./reader"
require "./writer"
require "./xml_parser"

struct Options
  property input : String?
  property output : String?
  property format : String?
end

options = Options.new

OptionParser.parse do |parser|
  parser.banner = "Usage: nbt -f <path> [options]"

  parser.on("-v", "--version", "Show version") { puts Nbt::VERSION; exit }
  parser.on("-h", "--help", "Show help") { puts parser; exit }
  parser.on("-i", "--input=PATH", "Path to an nbt file") { |path| options.input = path }
  parser.on("-o", "--output=PATH", "Output path") { |path| options.output = path }
  parser.on("-f", "--format=FORMAT", "xml,{dat,nbt}") { |format| options.format = format.downcase }
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
    root_tag = Compress::Gzip::Reader.open(file) do |gzip|
      Nbt::Reader.new(gzip).parse_tag
    end
    file.close
    root_tag
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
  options.format ||= "xml"
end

output_io =
  if output_path = options.output
    if options.format == "xml"
      File.open(output_path, "w")
    else
      File.open(output_path, "wb")
    end
  else
    # unless options.format == "xml"
    #   STDERR.puts "Unable to output to stdout with binary format, use -o"
    #   exit(1)
    # end

    STDOUT
  end

case options.format
when "xml"
  xml = XML.build(indent: 2) do |xml|
    Nbt::Writer.write_xml(nbt_data, xml)
  end

  output_io.puts(xml)
when "dat", "nbt"
  Compress::Gzip::Writer.open(output_io) do |gzip|
    Nbt::Writer.write(gzip, root_tag)
  end
end

output_io.close
