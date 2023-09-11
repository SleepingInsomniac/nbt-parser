module Nbt
  class Tag
    include Enumerable(Int8 | Int32 | Int64 | Tag)

    enum Id : UInt8
      End       =  0
      Byte      =  1
      Short     =  2
      Int       =  3
      Long      =  4
      Float     =  5
      Double    =  6
      ByteArray =  7
      String    =  8
      List      =  9
      Compound  = 10
      IntArray  = 11
      LongArray = 12
    end

    getter id : Id
    property name : String
    property payload : Nil | String | Int8 | Int16 | Int32 | Int64 | Float32 | Float64 | Array(Int8) | Array(Int32) | Array(Int64) | Array(Nbt::Tag)

    def initialize(@id, @name, @payload = nil)
    end

    def list_id : Id?
      return nil unless @id.list?

      if child = @payload.as(Array(Nbt::Tag))[0]?
        child.id
      else
        Id::End
      end
    end

    # Enumerable implementation
    def each
      if @payload.is_a?(Array(Int8) | Array(Int32) | Array(Int64) | Array(Nbt::Tag))
        @payload.as(Array(Int8) | Array(Int32) | Array(Int64) | Array(Nbt::Tag)).each do |item|
          yield item
        end
      end
    end

    # Get a child tag by specifying a name or index
    # ex: `tag["Data", 0]?`
    def []?(*path : Int | String)
      current_tag = self

      path.each do |path|
        break if current_tag.nil?

        # only tags have paths
        unless current_tag.is_a?(Tag)
          current_tag = nil
          break
        end

        current_tag =
          case path
          when Int
            current_tag.payload.as(Array(Int8) | Array(Int32) | Array(Int64) | Array(Nbt::Tag))[path]?
          when String
            unless current_tag.payload.is_a?(Array(Nbt::Tag))
              nil
            else
              current_tag.payload.as(Array(Nbt::Tag)).find { |t| t.name == path }
            end
          end
      end

      current_tag
    end

    # Unpack data in a long array that is packed by bits_per_entry
    def unpack(bits_per_entry : Int) : Array(UInt32)
      raise "Can only unpack LongArray" unless @id.long_array?

      unpacked = [] of UInt32
      return unpacked if @payload.nil?

      packed = @payload.as(Array(Int64))
      bitmask = (1_i64 << bits_per_entry) - 1_i64
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
    def pack(unpacked : Array(UInt32) | Array(Int32), bits_per_entry : Int)
      raise "Can only pack LongArray" unless @id.long_array?

      @payload.as(Array(Int64)).clear
      entries_per_packed = 64 // bits_per_entry

      unpacked.each_slice(entries_per_packed) do |packable|
        current_packed = 0_i64

        packable.each_with_index do |datum, i|
          current_packed |= (datum.to_i64 << (i * bits_per_entry))
        end

        @payload.as(Array(Int64)) << current_packed
      end

      self
    end
  end
end
