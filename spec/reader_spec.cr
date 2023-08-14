require "./spec_helper"

require "../src/reader"
require "../src/writer"
require "../src/tag"

describe Nbt::Reader do
  it "Reads ByteArray" do
    bytes = Bytes[
      Nbt::Tag::Id::ByteArray.value,
      0, 5, # length of name
      65, 65, 65, 65, 65,
      0, 0, 0, 5, # size of array
      255, 255, 255, 255, 255,
    ]

    io = IO::Memory.new(bytes)
    tag = Nbt::Reader.new(io).parse_tag

    tag.id.byte_array?.should be_true
    tag.name.should eq("AAAAA")
    tag.payload.should eq([255u8, 255u8, 255u8, 255u8, 255u8])
  end
end
