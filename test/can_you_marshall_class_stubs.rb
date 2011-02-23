

class F < Array

end

f = F.new(3, 4)

puts "f = #{f.inspect}, f.class=#{f.class}"

data = Marshal::dump(f)

f2 = Marshal::restore(data)

puts "f2 = #{f2.inspect}, f2.class=#{f2.class}"

