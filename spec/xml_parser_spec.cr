require "./spec_helper"

require "../src/reader"
require "../src/writer"
require "../src/tag"
require "../src/xml_parser"

describe Nbt::XmlParser do
  it "Parses negative values from int array" do
    xml = <<-XML
      <IntArray value="[447537198, 103891500, -1460469762, -1640371231]" name="WanderingTraderId"/>
    XML

    tag = Nbt::XmlParser.new(xml).parse
    tag.payload.as(Array(Int32))[2].should eq(-1460469762)
  end

  it "Parses list tags" do
    xml = <<-XML
      <List type="List">
        <List type="String">
          <String value="AAAAA">
        </List>
      </List
    XML

    tag = Nbt::XmlParser.new(xml).parse

    tag.payload.as(Array(Nbt::Tag)).first.should be_a(Nbt::Tag)

    tag.payload.as(Array(Nbt::Tag))
      .first.payload.as(Array(Nbt::Tag))
      .first.payload.should eq("AAAAA")
  end

  it "Parses longs" do
    xml = <<-XML
      <Long name="long" value="1234"/>
    XML

    tag = Nbt::XmlParser.new(xml).parse

    tag.name.should eq("long")
    tag.payload.should eq(1234_i64)
  end
end
