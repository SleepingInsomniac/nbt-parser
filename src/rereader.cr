require "./retag"

module Nbt
  class Reader
    getter io : IO

    def initialize(@io)
    end

    def read_tag
      tag_id = parse_id
      name = tag_id.end? ? "" : read_string
      payload = read_payload(tag_id)

      Tag[tag_id, name, payload]
    end

    def parse_id
      Tag::Id.from_value(io.read_bytes(UInt8))
    end

    def read_payload(tag_id)
      case tag_id
      when Tag::Id::End       then nil
      when Tag::Id::Byte      then read_number(Int8)
      when Tag::Id::Short     then read_number(Int16)
      when Tag::Id::Int       then read_number(Int32)
      when Tag::Id::Long      then read_number(Int64)
      when Tag::Id::Float     then read_number(Float32)
      when Tag::Id::Double    then read_number(Float64)
      when Tag::Id::ByteArray then Array(Int8).new(read_number(Int32)) { read_number(Int8) }
      when Tag::Id::String    then read_string
      when Tag::Id::List      then read_list
      when Tag::Id::Compound  then read_compound
      when Tag::Id::IntArray  then Array(Int32).new(read_number(Int32)) { read_number(Int32) }
      when Tag::Id::LongArray then Array(Int64).new(read_number(Int32)) { read_number(Int64) }
      else
        raise "Error: Unknown tag id #{tag_id.value}"
      end
    end

    def read_number(t = Int8)
      io.read_bytes(t, format: IO::ByteFormat::BigEndian)
    end

    def read_list
      list_id = parse_id
      Array(Tag).new(read_number(Int32)) do
        payload = read_payload(list_id)
        Tag[list_id.not_nil!, "", payload]
      end
    end

    def read_compound
      tags = Array(Tag).new
      loop do
        tag = read_tag
        break if tag.id == Tag::Id::End
        tags << tag
      end
      tags
    end

    def read_string
      buffer = Bytes.new(read_number(UInt16))
      io.read_fully(buffer)
      String.new(buffer)
    end
  end
end

bytes = Bytes[
  Nbt::Tag::Id::ByteArray.value,
  0, 5, # length of name
  65, 65, 65, 65, 65,
  0, 0, 0, 5, # size of array
  -100, 100, 3, 4, 5,
]

io = IO::Memory.new(bytes)
tag = Nbt::Reader.new(io).read_tag
puts tag

# case tag
# when Nbt::TagByteArray
#   puts tag.payload
# when Nbt::TagByte
#   puts tag.payload
# end
puts tag.payload
