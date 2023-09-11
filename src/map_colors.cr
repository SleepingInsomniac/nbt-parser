require "./color"

class MapColors
  property default_color : String = "#FFFFFF"
  property file_path : String
  property colors = {} of String => Color(UInt8)?
  getter missing = Set(String).new

  def initialize(@file_path)
    raise "#{file_path} does not exist!" unless File.exists?(@file_path)

    JSON.parse(File.read(@file_path)).as_h.each do |key, value|
      if v = value.as_s?
        begin
          @colors[key] = Color(UInt8).from_hex(v)
        rescue e
          STDERR.puts "error: #{key} => #{e}"
        end
      else
        @colors[key] = nil
      end
    end
  end

  def []?(key : String)
    @colors[key]?.tap do |v|
      @missing << key unless v
    end
  end

  def []=(key : String, value : String?)
    @colors[key] = value
  end
end
