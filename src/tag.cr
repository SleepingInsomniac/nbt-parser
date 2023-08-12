module Nbt
  class Tag
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
    getter list_id : Id?
    property payload : Array(Int32) | Array(Int64) | Array(Nbt::Tag) | Array(UInt8) | Float32 | Float64 | Int16 | Int32 | Int64 | String | UInt8 | Nil

    def initialize(@id, @name, @payload, @list_id = nil)
    end
  end
end
