module Nbt
  class Parser
    def self.parse_tag(io)
      tag_id = Tag::Id.new(io.read_bytes(UInt8))
      name = if tag_id.end?
               ""
             else
               read_string(io)
             end

      list_id = if tag_id.list?
                  Tag::Id.new(io.read_bytes(UInt8))
                else
                  nil
                end

      payload = parse_payload(io, tag_id, list_id)
      Tag.new(tag_id, name, payload, list_id)
    end

    def self.parse_payload(io, tag_id, list_id = nil)
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
        read_string(io)
      when Tag::Id::List
        list_size = io.read_bytes(Int32, format: IO::ByteFormat::BigEndian)
        tags = Array(Tag).new(list_size)
        list_size.times do
          payload = parse_payload(io, list_id.not_nil!)
          tags << Tag.new(list_id.not_nil!, "", payload)
        end
        tags
      when Tag::Id::Compound
        tags = Array(Tag).new
        loop do
          tag = parse_tag(io)
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
        # exit(1)
      end
    end

    def self.read_string(io : IO)
      size = io.read_bytes(UInt16, format: IO::ByteFormat::BigEndian)
      buffer = Bytes.new(size)
      io.read_utf8(buffer)
      String.new(buffer)
    end

    def self.parse_xml(xml)
      document = XML.parse(xml)
      if node = document.first_element_child
        parse_xml_tag(node)
      else
        Tag.new(Tag::Id::Compound, "", [] of Tag)
      end
    end

    def self.parse_xml_tag(node) : Tag
      tag_id = Tag::Id.parse(node.name)
      tag_name = node["name"]? || ""
      list_id = if string = node["type"]?
                  Tag::Id.parse(string)
                end

      payload = case tag_id
                when Tag::Id::Byte
                  node["value"].to_u8
                when Tag::Id::Short
                  node["value"].to_i16
                when Tag::Id::Int
                  node["value"].to_i32
                when Tag::Id::Long
                  node["value"].to_i64
                when Tag::Id::Float
                  node["value"].to_f32
                when Tag::Id::Double
                  node["value"].to_f64
                when Tag::Id::ByteArray
                  node["value"].split(/\D+/).reject(&.blank?).map(&.to_u8)
                when Tag::Id::String
                  node["value"]
                when Tag::Id::List, Tag::Id::Compound
                  node.children.select(&.element?).map do |child|
                    parse_xml_tag(child)
                  end
                when Tag::Id::IntArray
                  nums = node["value"].split(/\D+/).reject(&.blank?).map(&.to_i32)
                when Tag::Id::LongArray
                  node["value"].split(/\D+/).reject(&.blank?).map(&.to_i64)
                else
                  STDERR.puts "Error: Unknown tag id #{tag_id.value}"
                end

      Tag.new(tag_id, tag_name, payload, list_id)
    end
  end
end
