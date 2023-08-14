module Nbt
  class Reader
    getter io : IO

    def initialize(@io)
    end

    def parse_tag
      tag_id = parse_id
      name = tag_id.end? ? "" : read_string
      list_id = tag_id.list? ? parse_id : nil
      payload = parse_payload(tag_id, list_id)

      Tag.new(tag_id, name, payload, list_id)
    end

    def parse_id
      Tag::Id.from_value(io.read_bytes(UInt8))
    end

    def parse_payload(tag_id, list_id = nil)
      case tag_id
      when Tag::Id::End       then nil
      when Tag::Id::Byte      then io.read_bytes(UInt8)
      when Tag::Id::Short     then io.read_bytes(Int16, format: IO::ByteFormat::BigEndian)
      when Tag::Id::Int       then io.read_bytes(Int32, format: IO::ByteFormat::BigEndian)
      when Tag::Id::Long      then io.read_bytes(Int64, format: IO::ByteFormat::BigEndian)
      when Tag::Id::Float     then io.read_bytes(Float32, format: IO::ByteFormat::BigEndian)
      when Tag::Id::Double    then io.read_bytes(Float64, format: IO::ByteFormat::BigEndian)
      when Tag::Id::ByteArray then Array(UInt8).new(array_size) { io.read_bytes(UInt8) }
      when Tag::Id::String    then read_string
      when Tag::Id::List
        size = io.read_bytes(Int32, format: IO::ByteFormat::BigEndian)
        tags = Array(Tag).new(size) do
          payload = parse_payload(list_id.not_nil!)
          Tag.new(list_id.not_nil!, "", payload)
        end
      when Tag::Id::Compound
        tags = Array(Tag).new
        loop do
          tag = parse_tag
          break if tag.id == Tag::Id::End
          tags << tag
        end
        tags
      when Tag::Id::IntArray
        Array(Int32).new(array_size) { io.read_bytes(Int32, format: IO::ByteFormat::BigEndian) }
      when Tag::Id::LongArray
        Array(Int64).new(array_size) { io.read_bytes(Int64, format: IO::ByteFormat::BigEndian) }
      else
        STDERR.puts "Error: Unknown tag id #{tag_id.value}"
        exit(1)
      end
    end

    # For length of array values (not List)
    def array_size
      io.read_bytes(Int32, format: IO::ByteFormat::BigEndian)
    end

    def read_string
      size = io.read_bytes(UInt16, format: IO::ByteFormat::BigEndian)
      buffer = Bytes.new(size)
      io.read_utf8(buffer)
      String.new(buffer)
    end
  end
end
