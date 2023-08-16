require "xml"

module Nbt
  class Writer
    def self.write(io : IO, tag : Tag)
      # Write tag ID
      io.write_bytes(tag.id.value.to_u8, IO::ByteFormat::BigEndian)
      return if tag.id.end?

      # Write tag name
      io.write_bytes(tag.name.bytesize.to_u16, IO::ByteFormat::BigEndian)
      io.write(tag.name.to_slice)

      write_payload(io, tag)
    rescue e
      STDERR.puts "Unable to write tag:"
      STDERR.puts tag.id
      STDERR.puts tag.name
      STDERR.puts tag.payload
      STDERR.puts tag.list_id

      raise e
    end

    def self.write_payload(io : IO, tag : Tag)
      # Write list_id
      if tag.id.list?
        io.write_bytes(tag.list_id.not_nil!.value, IO::ByteFormat::BigEndian)
      end

      # Write size
      case tag.id
      when Tag::Id::ByteArray
        io.write_bytes(tag.payload.as(Array(Int8)).size.to_i32, IO::ByteFormat::BigEndian)
      when Tag::Id::String
        io.write_bytes(tag.payload.as(String).bytesize.to_u16, IO::ByteFormat::BigEndian)
      when Tag::Id::List
        io.write_bytes(tag.payload.as(Array(Tag)).size.to_i32, IO::ByteFormat::BigEndian)
      when Tag::Id::IntArray
        io.write_bytes(tag.payload.as(Array(Int32)).size.to_i32, IO::ByteFormat::BigEndian)
      when Tag::Id::LongArray
        io.write_bytes(tag.payload.as(Array(Int64)).size.to_i32, IO::ByteFormat::BigEndian)
      end

      # Write payload
      case tag.id
      when Tag::Id::Byte
        io.write_bytes(tag.payload.as(Int8))
      when Tag::Id::Short
        io.write_bytes(tag.payload.as(Int16), IO::ByteFormat::BigEndian)
      when Tag::Id::Int
        io.write_bytes(tag.payload.as(Int32), IO::ByteFormat::BigEndian)
      when Tag::Id::Long
        io.write_bytes(tag.payload.as(Int64), IO::ByteFormat::BigEndian)
      when Tag::Id::Float
        io.write_bytes(tag.payload.as(Float32), IO::ByteFormat::BigEndian)
      when Tag::Id::Double
        io.write_bytes(tag.payload.as(Float64), IO::ByteFormat::BigEndian)
      when Tag::Id::ByteArray
        tag.payload.as(Array(Int8)).each do |byte|
          io.write_bytes(byte)
        end
      when Tag::Id::String
        io.write(tag.payload.as(String).to_slice)
      when Tag::Id::List
        tag.payload.as(Array(Tag)).each do |tag|
          write_payload(io, tag)
        end
      when Tag::Id::Compound
        tag.payload.as(Array(Tag)).each do |tag|
          write(io, tag)
        end
        io.write_bytes(Tag::Id::End.value) # Write ending tag
      when Tag::Id::IntArray
        tag.payload.as(Array(Int32)).each do |value|
          io.write_bytes(value, IO::ByteFormat::BigEndian)
        end
      when Tag::Id::LongArray
        tag.payload.as(Array(Int64)).each do |value|
          io.write_bytes(value, IO::ByteFormat::BigEndian)
        end
      end
    end

    def self.write_xml(tag : Nbt::Tag, xml : XML::Builder)
      payload = tag.payload

      case payload
      when Array(Nbt::Tag)
        xml.element(tag.id.to_s) do
          xml.attribute("name", tag.name) unless tag.name.blank?
          xml.attribute("type", tag.list_id) if tag.id.list?

          payload.each do |child|
            write_xml(child, xml)
          end
        end
      when Array(Int8), Array(Int32), Array(Int64)
        xml.element(tag.id.to_s) do
          xml.attribute("name", tag.name) unless tag.name.blank?

          payload.each do |child|
            case child
            when Int8  then xml.element(Tag::Id::Byte.to_s, value: child)
            when Int32 then xml.element(Tag::Id::Int.to_s, value: child)
            when Int64 then xml.element(Tag::Id::Long.to_s, value: child)
            else
              raise "Array with wrong type!"
            end
          end
        end
      else
        xml.element(tag.id.to_s) do
          xml.attribute("name", tag.name) unless tag.name.blank?
          xml.attribute("value", tag.payload)
        end
      end
    end
  end
end
