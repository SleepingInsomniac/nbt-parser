require "./spec_helper"

require "../src/reader"
require "../src/writer"
require "../src/tag"

describe Nbt::Writer do
  it "Reads and writes correctly" do
    io = IO::Memory.new
    tag = Nbt::Tag.new(Nbt::Tag::Id::String, "TestString", "TestString Value")
    Nbt::Writer.write(io, tag)

    io.rewind
    new_tag = Nbt::Reader.new(io).parse_tag

    new_tag.id.should eq(tag.id)
    new_tag.name.should eq(tag.name)
    new_tag.payload.should eq(tag.payload)
  end

  it "Writes lists to nbt format" do
    io = IO::Memory.new
    tag = Nbt::Tag.new(Nbt::Tag::Id::List, "TestList", [
      Nbt::Tag.new(Nbt::Tag::Id::Int, "", 42),
      Nbt::Tag.new(Nbt::Tag::Id::Int, "", 24),
    ])
    Nbt::Writer.write(io, tag)

    io.rewind
    new_tag = Nbt::Reader.new(io).parse_tag

    new_tag.id.should eq(tag.id)
    new_tag.name.should eq(tag.name)
    new_tag.payload.as(Array(Nbt::Tag))[0].payload.should eq(42)
    new_tag.payload.as(Array(Nbt::Tag))[1].payload.should eq(24)
  end

  it "writes lists of lists" do
    io = IO::Memory.new
    tag = Nbt::Tag.new(Nbt::Tag::Id::List, "TestList", [
      Nbt::Tag.new(Nbt::Tag::Id::List, "", [] of Nbt::Tag),
      Nbt::Tag.new(Nbt::Tag::Id::List, "", [] of Nbt::Tag),
    ])
    Nbt::Writer.write(io, tag)

    io.rewind
    new_tag = Nbt::Reader.new(io).parse_tag

    new_tag.id.should eq(tag.id)
    new_tag.name.should eq(tag.name)
    list_payload = new_tag.payload.as(Array(Nbt::Tag))
    list_payload[0].payload.should eq([] of Nbt::Tag)
    list_payload[1].payload.should eq([] of Nbt::Tag)
  end

  it "Writes lists of lists to XML" do
    io = IO::Memory.new
    tag = Nbt::Tag.new(Nbt::Tag::Id::List, "MyList", [
      Nbt::Tag.new(Nbt::Tag::Id::List, "", [
        Nbt::Tag.new(Nbt::Tag::Id::String, "", "AAAAA"),
      ]),
    ])

    xml = XML.build(indent: 2) do |xml|
      Nbt::Writer.write_xml(tag, xml)
    end

    xml.should eq(<<-XML)
    <?xml version="1.0"?>
    <List name="MyList" type="List">
      <List type="String">
        <String value="AAAAA"/>
      </List>
    </List>\n
    XML
  end
end
