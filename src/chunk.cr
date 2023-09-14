require "./system"

module Nbt
  SECTION_SIZE = 16
  BIOME_SIZE   =  4

  # A chunk stores block data in a long array packed by number of bits nessesary
  class Chunk
    @nbt : Tag
    alias Coords = Set(Tuple(Int32, Int32))
    @structures : Hash(String, Coords)?

    def initialize(@nbt : Tag)
    end

    # Returns 24 in the current version
    getter section_count do
      @nbt["sections"].as(Array(Nbt::Tag)).size
    end

    getter world_surface : Array(UInt32)? do
      if tag = @nbt["Heightmaps", "WORLD_SURFACE"]?
        tag.as(Nbt::Tag).unpack(9)
      end
    end

    getter ocean_floor : Array(UInt32)? do
      if tag = @nbt["Heightmaps", "OCEAN_FLOOR"]?
        tag.as(Nbt::Tag).unpack(9)
      end
    end

    getter structures : Hash(String, Coords) do
      if tag = @nbt["structures", "References"]?
        _structures = {} of String => Coords

        tag.each do |ref_tag|
          ref_tag = ref_tag.as(Nbt::Tag)
          _structures[ref_tag.name] = Coords.new

          ref_tag.payload.as(Array(Int64)).each do |coord|
            slice = pointerof(coord).as(Pointer(Int32)).to_slice(2)

            if System.little_endian?
              x, z = slice
            else
              z, x = slice
            end

            _structures[ref_tag.name] << {x, z}
          end
        end

        _structures
      else
        {} of String => Coords
      end
    end

    getter sections : Array(Section) do
      @nbt["sections"].as(Nbt::Tag).payload.as(Array(Nbt::Tag)).map do |tag|
        Section.new(tag)
      end
    end

    def block(x : Int, y : Int, z : Int)
      section_index = y // SECTION_SIZE
      local_y = y % SECTION_SIZE
      sections[section_index].block(x, local_y, z)
    end

    def biome(x : Int, y : Int, z : Int)
      section_index = y // SECTION_SIZE
      local_y = y % SECTION_SIZE
      sections[section_index].biome(x, local_y, z)
    end
  end

  class Section
    @nbt : Tag

    def initialize(@nbt)
    end

    # Number of bits required to represent the max index of a palette
    # Min bits is 4
    getter palette_bits : UInt8 do
      palette_size = palette.payload.as(Array(Nbt::Tag)).size
      bits = Math.log2(palette_size).ceil.to_u8
      bits < 4u8 ? 4u8 : bits
    end

    getter data : Nbt::Tag do
      @nbt["block_states", "data"]
    end

    getter palette : Nbt::Tag do
      @nbt["block_states", "palette"]
    end

    # Array of indicies into the palette
    getter blocks : Array(UInt32) do
      data.unpack(palette_bits)
    end

    # Gets the block index into the cube of section data
    def index(x : Int, y : Int, z : Int, size : Int)
      y * (size ** 2) + z * size + x
    end

    # Gets the palette tag from the index in the data
    def block(x : Int, y : Int, z : Int)
      palette_index = blocks[index(x, y, z, SECTION_SIZE)]
      palette.payload.as(Array(Nbt::Tag))[palette_index]
    end

    getter biome_palette : Nbt::Tag do
      @nbt["biomes", "palette"]
    end

    getter biome_data : Nbt::Tag? do
      @nbt["biomes", "data"]?
    end

    getter biome_palette_bits : UInt8 do
      palette_size = biome_palette.payload.as(Array(Nbt::Tag)).size
      Math.log2(palette_size).ceil.to_u8
    end

    # Array of indicies into the palette
    getter biomes : Array(UInt32)? do
      if biome_palette_bits > 0
        biome_data.not_nil!.unpack(biome_palette_bits)
      end
    end

    def biome(x : Int, y : Int, z : Int)
      if biomes
        b_index = index(x // BIOME_SIZE, y // BIOME_SIZE, z // BIOME_SIZE, BIOME_SIZE)
        palette_index = biomes.not_nil![b_index]
      else
        palette_index = 0
      end

      biome_palette.payload.as(Array(Nbt::Tag))[palette_index]
    end
  end
end
