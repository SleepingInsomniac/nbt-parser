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
end
