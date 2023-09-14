module Nbt
  class TagIntArray < TagArray(Int32)
    @id = Id::IntArray
  end
end
