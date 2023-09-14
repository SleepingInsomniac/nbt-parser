#!/usr/bin/env crystal

module Nbt
  abstract class TagArray(T) < Tag
    property payload : Array(T)
  end
end

require "./tag_array/tag_byte_array"
require "./tag_array/tag_int_array"
require "./tag_array/tag_long_array"
