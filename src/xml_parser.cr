require "xml"
require "./tag"

module Nbt
  class XmlParser
    getter xml : String | IO

    def initialize(@xml)
    end

    def parse
      document = XML.parse(xml)
      if node = document.first_element_child
        parse_xml_tag(node)
      else
        Tag.new(Tag::Id::Compound, "", [] of Tag)
      end
    end

    def parse_xml_tag(node) : Tag
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
                  node["value"].split(/[^\d\-]+/).reject(&.blank?).map(&.to_u8)
                when Tag::Id::String
                  node["value"]
                when Tag::Id::List, Tag::Id::Compound
                  node.children.select(&.element?).map do |child|
                    parse_xml_tag(child)
                  end
                when Tag::Id::IntArray
                  nums = node["value"].split(/[^\d\-]+/).reject(&.blank?).map(&.to_i32)
                when Tag::Id::LongArray
                  node["value"].split(/[^\d\-]+/).reject(&.blank?).map(&.to_i64)
                else
                  STDERR.puts "Error: Unknown tag id #{tag_id.value}"
                end

      Tag.new(tag_id, tag_name, payload)
    end
  end
end
