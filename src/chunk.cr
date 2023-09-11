module Nbt
  # A chunk stores block data in a long array packed by number of bits nessesary
  class Chunk
    SECTION_SIZE = 16
    BIOME_SIZE   =  4

    # Get which section a block belongs to based on the *y* index
    def self.section_index(y : Int) : Int
      y // 16
    end

    # Gets the 3d index into an array (Usually unpacked from the LongArray tag)
    def self.cube_index(x : Int, y : Int, z : Int, cube_size : Int = SECTION_SIZE) : Int
      y * (cube_size ** 2) + z * cube_size + x
    end

    # TODO: Not used - Move to tag?
    # *data* is a byte array, in which 1 byte stores 2 values (2 nibbles).
    # Skylight and Blocklight are 2048 byte arrays that use this format.
    # ex: `block_light = nibble4(block_light_data, block_index)`
    def self.nibble4(data : Array(UInt8), index : Int) : UInt8
      n = data[index // 2]      # 2 values per byte
      n = n >> 4 if index.even? # little endian (shift by 4 bits)
      n & 0xF
    end

    @nbt : Tag
    # TODO - determine number of sections from nbt
    @sections = Array(Array(UInt32)?).new(24) { nil }
    @biomes = Array(Array(UInt32)?).new(24) { nil }
    @world_surface : Array(UInt32)?
    @ocean_floor : Array(UInt32)?

    def initialize(@nbt : Tag)
    end

    def section_count
      @sections = @nbt["sections"].as(Array(Nbt::Tag)).count
    end

    def section_palette(section_index : Int)
      if palette = @nbt["sections", section_index, "block_states", "palette"]?
        palette.as(Nbt::Tag)
      else
        raise "Palette not found for section #{section_index}"
      end
    end

    # Number of bits required to represent the max index of a palette
    # Min bits is 4
    def palette_bits(section_index : Int) : UInt8
      bits = Math.log2(section_palette(section_index).payload.as(Array(Nbt::Tag)).size).ceil.to_u8
      bits < 4u8 ? 4u8 : bits
    end

    # Load a section by unpacking the data which are indexes into the palette
    def section(index : Int)
      return @sections[index]? if @sections[index]?

      if data_tag = @nbt["sections", index, "block_states", "data"]?
        bits = palette_bits(index)
        @sections[index] = data_tag.as(Nbt::Tag).unpack(bits)
      end

      @sections[index]?
    end

    def biomes(section_index : Int)
      return @biomes[section_index]? if @biomes[section_index]

      if palette = @nbt["sections", section_index, "biomes", "palette"]?
        palette_size = palette.as(Nbt::Tag).payload.as(Array(Nbt::Tag)).size

        if palette_size == 1
          @biomes[section_index] = Array(UInt32).new(64) { 0u32 }
          return @biomes[section_index]?
        end

        if data_tag = @nbt["sections", section_index, "biomes", "data"]?
          bits = Math.log2(palette_size).ceil.to_u8
          data_tag = @nbt["sections", section_index, "biomes", "data"]?.not_nil!.as(Nbt::Tag)
          @biomes[section_index] = data_tag.unpack(bits)
          return @biomes[section_index]?
        end
      end

      @sections[section_index]?
    end

    def world_surface : Array(UInt32)?
      return @world_surface if @world_surface

      if world_surface_tag = @nbt["Heightmaps", "WORLD_SURFACE"]?
        @world_surface = world_surface_tag.as(Nbt::Tag).unpack(9)
      end

      @world_surface
    end

    def ocean_floor : Array(UInt32)?
      return @ocean_floor if @ocean_floor

      if tag = @nbt["Heightmaps", "OCEAN_FLOOR"]?
        @ocean_floor = tag.as(Nbt::Tag).unpack(9)
      end

      @ocean_floor
    end

    # def structures
    #   if tag = @nbt["structures"]?
    # end

    def block(x : Int, y : Int, z : Int)
      if s = section(y // 16)
        section_y = y % 16
        index = self.class.cube_index(x, section_y, z)
        palette_index = s[index]
        section_palette(y // 16).payload.as(Array(Nbt::Tag))[palette_index]
      else
        nil
      end
    end

    def biome(x : Int, y : Int, z : Int)
      section_index = y // 16
      local_y = y % 16

      if palette = @nbt["sections", section_index, "biomes", "palette"]?
        if b = biomes(section_index)
          index = self.class.cube_index(x // BIOME_SIZE, local_y // BIOME_SIZE, z // BIOME_SIZE, BIOME_SIZE)
          palette_index = b[index]
          palette.as(Nbt::Tag).payload.as(Array(Nbt::Tag))[palette_index].payload.as(String)
        end
      end
    end
  end
end
