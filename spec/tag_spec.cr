require "./spec_helper"

require "../src/tag"

describe Nbt::Tag do
  describe "#[]?" do
    it "finds by name" do
      tag = Nbt::Tag.new(Nbt::Tag::Id::Compound, "TestTag", [
        Nbt::Tag.new(Nbt::Tag::Id::Int, "Num1", 42),
        Nbt::Tag.new(Nbt::Tag::Id::Int, "Num2", 24),
      ])

      tag["Num1"]?.not_nil!.as(Nbt::Tag).name.should eq("Num1")
      tag["Foo"]?.should eq(nil)
    end

    it "finds by index" do
      tag = Nbt::Tag.new(Nbt::Tag::Id::Compound, "TestTag", [
        Nbt::Tag.new(Nbt::Tag::Id::Int, "Num1", 42),
        Nbt::Tag.new(Nbt::Tag::Id::Int, "Num2", 24),
      ])

      tag[0]?.not_nil!.as(Nbt::Tag).name.should eq("Num1")
    end

    it "finds given a path" do
      tag = Nbt::Tag.new(Nbt::Tag::Id::Compound, "TestTag", [
        Nbt::Tag.new(Nbt::Tag::Id::Compound, "Tag1", [
          Nbt::Tag.new(Nbt::Tag::Id::Int, "Tag2", 24),
        ]),
      ])

      tag["Tag1", "Tag2"]?.not_nil!.as(Nbt::Tag).payload.should eq(24)
    end
  end

  describe "#pack" do
    it "unpacks long arrays" do
      tag = Nbt::Tag.new(Nbt::Tag::Id::LongArray, "TestTag", [
        -8608480567731124088_i64, -8608480567731124088_i64,
      ])
      unpacked = tag.unpack(4)
      unpacked.should eq([
        0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8,
        0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8,
        0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8,
        0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8,
      ] of UInt32)
    end

    it "packs into long arrays" do
      unpacked = [
        0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8,
        0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8,
        0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8,
        0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8, 0x8,
      ] of UInt32

      tag = Nbt::Tag.new(Nbt::Tag::Id::LongArray, "TestTag", [] of Int64)
      tag.pack(unpacked, 4)
      tag.payload.should eq([-8608480567731124088_i64, -8608480567731124088_i64])
    end
  end
end
