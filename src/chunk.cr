module Nbt
  class Chunk
    # A chunk stores data in a long array packed by number of bits nessesary

    # Unpack data in a long array that is packed by bits_per_entry
    def self.unpack_array(packed : Array(Int64 | UInt64), bits_per_entry : Int) : Array(UInt32)
      unpacked = [] of UInt32
      bitmask = (1_u64 << bits_per_entry) - 1_u64
      entries_per_packed = 64 // bits_per_entry

      packed.each do |data|
        shifted_data = data

        entries_per_packed.times do
          unpacked << (shifted_data & bitmask).to_u32
          shifted_data >>= bits_per_entry
        end
      end

      unpacked
    end

    # Pack an array into a long_array by bits_per_entry
    def self.pack_array(unpacked : Array(UInt32), bits_per_entry : Int) : Array(UInt64)
      packed = [] of UInt64
      entries_per_packed = 64 // bits_per_entry

      unpacked.each_slice(entries_per_packed) do |packable|
        current_packed = 0_u64

        packable.each_with_index do |datum, i|
          current_packed |= (datum.to_i64 << (i * bits_per_entry))
        end

        packed << current_packed
      end

      packed
    end
  end
end
