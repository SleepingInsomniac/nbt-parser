module Nbt
  abstract class Tag
    alias TagNumericT = Int8 | Int16 | Int32 | Int64 | Float32 | Float64
    alias TagArrayT = Array(Int8) | Array(Int32) | Array(Int64) | Array(Tag)
    alias TaggableT = Nil | String | TagNumericT | TagArrayT

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

    def self.[](id : Id, name : String, payload : TaggableT)
      case payload
      when Nil          then TagEnd.new(name, payload)
      when Int8         then TagByte.new(name, payload)
      when Int16        then TagShort.new(name, payload)
      when Int32        then TagInt.new(name, payload)
      when Int64        then TagLong.new(name, payload)
      when Float32      then TagFloat.new(name, payload)
      when Float64      then TagDouble.new(name, payload)
      when Array(Int8)  then TagByteArray.new(name, payload)
      when String       then TagString.new(name, payload)
      when Array(Tag)   then id.list? ? TagList.new(name, payload) : TagCompound.new(name, payload)
      when Array(Int32) then TagIntArray.new(name, payload)
      when Array(Int64) then TagLongArray.new(name, payload)
      else
        raise "Unknown payload type #{id}"
      end
    end

    getter id : Id = Id::End
    property name : String

    def initialize(@name, @payload)
    end

    abstract def payload : TaggableT
  end
end

require "./tag/tag_end"
require "./tag/tag_numeric"
require "./tag/tag_array"
require "./tag/tag_string"
require "./tag/tag_list"
require "./tag/tag_compound"
