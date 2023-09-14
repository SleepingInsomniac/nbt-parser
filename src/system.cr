module System
  # Detect if the byte order is little endian
  def self.little_endian?
    n : Int32 = 1
    pointerof(n).as(Pointer(UInt32)).value == 1
  end

  def self.big_endian?
    !little_endian?
  end
end
