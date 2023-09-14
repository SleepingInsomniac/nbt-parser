module Nbt
  class TagList < Tag
    @id = Id::List
    property payload : Array(Tag)
  end
end
