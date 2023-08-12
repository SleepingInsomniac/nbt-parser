require "./spec_helper"

require "../src/parser"
require "../src/writer"
require "../src/tag"

describe "Nbt" do
  it "Reads and writes correctly" do
    io = IO::Memory.new
    tag = Nbt::Tag.new(Nbt::Tag::Id::String, "TestString", "TestString Value")
    Nbt::Writer.write(io, tag)

    io.rewind
    new_tag = Nbt::Parser.parse_tag(io)

    new_tag.id.should eq(tag.id)
    new_tag.name.should eq(tag.name)
    new_tag.payload.should eq(tag.payload)
  end
end
