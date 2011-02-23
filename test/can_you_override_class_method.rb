
class C
  def class
    Integer
  end

end

c = C.new
puts "c.class = #{c.class}" #  -> Integer...

# And it works....

puts "C === c -> #{C === c}"  # -> true
puts "Integer === c -> #{Integer === c}"        # -> false

