module Nbt
  class TagCompound < Tag
    @id = Id::Compound
    property payload : Array(Tag)
  end
end
