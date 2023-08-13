module Nbt
  class Reader
    getter io : IO

    def initialize(@io)
    end

    def parse_tag
      tag_id = Tag::Id.from_value(io.read_bytes(UInt8))
      name = tag_id.end? ? "" : read_string

      list_id = tag_id.list? ? Tag::Id.new(io.read_bytes(UInt8)) : nil

      payload = parse_payload(tag_id, list_id)
      Tag.new(tag_id, name, payload, list_id)
    end

    def parse_payload(tag_id, list_id = nil)
      payload_value =
        case tag_id
        when Tag::Id::End
          nil
        when Tag::Id::Byte
          io.read_bytes(UInt8)
        when Tag::Id::Short
          io.read_bytes(Int16, format: IO::ByteFormat::BigEndian)
        when Tag::Id::Int
          io.read_bytes(Int32, format: IO::ByteFormat::BigEndian)
        when Tag::Id::Long
          io.read_bytes(Int64, format: IO::ByteFormat::BigEndian)
        when Tag::Id::Float
          io.read_bytes(Float32, format: IO::ByteFormat::BigEndian)
        when Tag::Id::Double
          io.read_bytes(Float64, format: IO::ByteFormat::BigEndian)
        when Tag::Id::ByteArray
          size = io.read_bytes(UInt8)
          array = Array(UInt8).new(size)
          size.times do
            array << io.read_bytes(UInt8)
          end
          array
        when Tag::Id::String
          read_string
        when Tag::Id::List
          list_size = io.read_bytes(Int32, format: IO::ByteFormat::BigEndian)
          tags = Array(Tag).new(list_size)
          list_size.times do
            payload = parse_payload(list_id.not_nil!)
            tags << Tag.new(list_id.not_nil!, "", payload)
          end
          tags
        when Tag::Id::Compound
          tags = Array(Tag).new
          loop do
            tag = parse_tag
            break if tag.id == Tag::Id::End
            tags << tag
          end
          tags
        when Tag::Id::IntArray
          size = io.read_bytes(Int32, format: IO::ByteFormat::BigEndian)
          array = Array(Int32).new(size)
          size.times do
            array << io.read_bytes(Int32, format: IO::ByteFormat::BigEndian)
          end
          array
        when Tag::Id::LongArray
          size = io.read_bytes(Int32, format: IO::ByteFormat::BigEndian)
          array = Array(Int64).new(size)
          size.times do
            array << io.read_bytes(Int64, format: IO::ByteFormat::BigEndian)
          end
          array
        else
          STDERR.puts "Error: Unknown tag id #{tag_id.value}"
          exit(1)
        end

      payload_value
    end

    def read_string
      size = io.read_bytes(UInt16, format: IO::ByteFormat::BigEndian)
      buffer = Bytes.new(size)
      io.read_utf8(buffer)
      String.new(buffer)
    end
  end
end
