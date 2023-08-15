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

  it "reads a list of lists" do
    bytes = Bytes[
      Nbt::Tag::Id::List.value,   # Type list
      0, 5,                       # length of name
      65, 65, 65, 65, 65,         # Name of tag
      Nbt::Tag::Id::List.value,   # List id
      0, 0, 0, 1,                 # size of list
      Nbt::Tag::Id::String.value, # First payload List id
      0, 0, 0, 1,                 # Number of strings in list
      0, 5,                       # Length of string
      65, 65, 65, 65, 65          # String payload
    ]

    io = IO::Memory.new(bytes)
    tag = Nbt::Reader.new(io).parse_tag

    tag.payload.as(Array(Nbt::Tag)).first.should be_a(Nbt::Tag)

    tag.payload.as(Array(Nbt::Tag))
      .first.payload.as(Array(Nbt::Tag))
      .first.payload.should eq("AAAAA")
  end
end
