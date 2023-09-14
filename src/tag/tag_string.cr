module Nbt
  class TagString < Tag
    @id = Id::String
    property payload : String
  end
end
