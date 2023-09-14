#!/usr/bin/env crystal

module Nbt
  abstract class TagNumeric(T) < Tag
    property payload : T
  end

  class TagByte < TagNumeric(Int8)
    @id = Id::Byte
  end

  class TagShort < TagNumeric(Int16)
    @id = Id::Short
  end

  class TagInt < TagNumeric(Int32)
    @id = Id::Int
  end

  class TagLong < TagNumeric(Int64)
    @id = Id::Long
  end

  class TagFloat < TagNumeric(Float32)
    @id = Id::Float
  end

  class TagDouble < TagNumeric(Float64)
    @id = Id::Double
  end
end
