module Nbt
  class TagByteArray < TagArray(Int8)
    @id = Id::ByteArray
  end
end
