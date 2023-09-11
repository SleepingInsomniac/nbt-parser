struct Color(T)
  WHITE_8 = Color(UInt8).new(255, 255, 255)

  property r : T
  property g : T
  property b : T
  property a : T = T::MAX

  # Create from values that range from 0.0 to 1.0
  def self.from_f(r : Float, g : Float, b : Float, a : Float = 0.0)
    new(T.new(T::MAX * r), T.new(T::MAX * g), T.new(T::MAX * b), T.new(T::MAX * a))
  end

  def self.from_hex(hex : String)
    hex = hex.gsub(/^#/, "")
    values = if hex.size <= 4
               hex.chars.map { |c| T.new((c.to_s * 2).to_u8(16)) }.to_a
             else
               hex.chars.each_slice(2).map { |c| T.new(c.join.to_u8(16)) }.to_a
             end

    new(values[0], values[1], values[2], values[3]? || T::MAX)
  end

  def initialize(@r, @g, @b, @a = T::MAX)
  end

  def initialize(r : Number, g : Number, b : Number, a : Number = T::MAX)
    @r = T.new(r)
    @g = T.new(g)
    @b = T.new(b)
    @a = T.new(a)
  end

  def *(factor : Number)
    new_r = T.new((@r.to_u32 * factor).clamp(0, T::MAX))
    new_g = T.new((@g.to_u32 * factor).clamp(0, T::MAX))
    new_b = T.new((@b.to_u32 * factor).clamp(0, T::MAX))

    Color(T).new(new_r, new_g, new_b, @a)
  end

  def to_s
    to_hex
  end

  def to_hex
    hex = {@r, @g, @b, @a}.map { |c| c.to_s(16) }.join.upcase
    '#' + hex
  end

  # Combine with *other* via Alpha Compositing
  # see https://en.wikipedia.org/wiki/Alpha_compositing
  def over(other : Color(T)) : Color(T)
    if a == T::MAX
      self
    elsif a.zero?
      other
    else
      alpha_a = a.to_f / T::MAX
      alpha_b = other.a / T::MAX

      factor_1 = alpha_b * (1 - alpha_a)
      factor_2 = alpha_a + factor_1

      new_r = ((r * alpha_a) + (other.r * factor_1)) / factor_2
      new_g = ((g * alpha_a) + (other.g * factor_1)) / factor_2
      new_b = ((b * alpha_a) + (other.b * factor_1)) / factor_2
      new_a = factor_2 * T::MAX

      Color.new(T.new(new_r), T.new(new_g), T.new(new_b), T.new(new_a))
    end
  end

  def to_f32
    {@r / T::MAX, @g / T::MAX, @b / T::MAX, @a / T::MAX}
  end

  # Multiply colors
  def multiply(other : Color(T)) : Color(T)
    r1, b1, g1, a1 = to_f32
    r2, b2, g2, a2 = other.to_f32

    Color(T).from_f(r1 * r2, b1 * b2, g1 * g2, a1 * a2)
  end
end
