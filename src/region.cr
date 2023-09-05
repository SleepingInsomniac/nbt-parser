require "compress/gzip"
require "compress/zlib"

require "./tag"

module Nbt
  class Region
    CHUNK_SIZE = 16 # blocks
    SIZE       = 32 # chunks

    def self.region_coords(x : Float64, z : Float64)
      {
        x: (x / (CHUNK_SIZE * SIZE)).floor,
        z: (z / (CHUNK_SIZE * SIZE)).floor,
      }
    end

    def self.chunk_coords(x : Float64, z : Float64)
      {
        x: (x / CHUNK_SIZE).to_i % SIZE,
        z: (z / CHUNK_SIZE).to_i % SIZE,
      }
    end

    # A region file has 1024 entries of 4 bytes followed by 1024 entries for 4 byte timestamps
    struct Header
      ENTRIES   = 1024 # Number of entries in the header
      BYTE_SIZE =    4 # Size of an entry in bytes

      getter x : Int32
      getter z : Int32

      @offset : Int32? = nil

      def initialize(@x, @z)
      end

      # returns the heander entry offset for a chunk at *x* and *z* coordinates.
      def offset
        @offset ||= BYTE_SIZE * ((@x & 31) + (@z & 31) * 32)
        @offset.not_nil!
      end

      # The timestamps are listed in the second part of the header
      def timestamp_offset
        offset + (ENTRIES * BYTE_SIZE)
      end
    end

    getter io : IO

    def initialize(@io)
    end

    def timestamp(x : Int32, z : Int32)
      header = Header.new(x, z)
      @io.seek(header.timestamp_offset)
      @io.read_bytes(UInt32, IO::ByteFormat::BigEndian)
    end

    # Parameters:
    # - *x* : X coordinate of the chunk
    # - *z* : Z coordinate of the chunk
    def read_chunk(x : Int32, z : Int32)
      header = Header.new(x, z)
      @io.seek(header.offset)

      entry = @io.read_bytes(UInt32, IO::ByteFormat::BigEndian)

      data_location = (entry >> 8) * 4096 # First 3 bytes
      size = (entry & 0xFF) * 4096        # Last byte

      return nil if size == 0

      @io.seek(header.timestamp_offset)
      timestamp = @io.read_bytes(UInt32, IO::ByteFormat::BigEndian)

      @io.seek(data_location)
      data_length = @io.read_bytes(Int32, IO::ByteFormat::BigEndian)
      compression_type = @io.read_bytes(UInt8)

      compressed_data = Bytes.new(data_length - 1)
      @io.read_fully(compressed_data)
      memory = IO::Memory.new(compressed_data)

      nbt_tag =
        case compression_type
        when 1 # GZip (RFC1952) (unused in practice)
          Compress::Gzip::Reader.open(memory) do |gzip|
            Reader.new(gzip).parse_tag
          end
        when 2 # Zlib (RFC1950)
          Compress::Zlib::Reader.open(memory) do |zlib|
            Reader.new(zlib).parse_tag
          end
        when 3 # Uncompressed (unused in practice)
          Reader.new(memory).parse_tag
        else
          raise "Unknown compression type for chunk"
        end
    rescue e : IO::EOFError
      nil
    end
  end
end
