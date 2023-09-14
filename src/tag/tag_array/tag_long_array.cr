module Nbt
  class TagLongArray < TagArray(Int64)
    @id = Id::LongArray
  end
end
