require "./spec_helper"

require "../src/reader"
require "../src/writer"
require "../src/tag"

describe "Nbt" do
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
end
