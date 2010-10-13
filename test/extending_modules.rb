
# Basicly Ruby supports multiple inheritance.
# But there never is an ambiguous call.
# We just go up the ancestor tree.
# later includes overwrite higher-up entries.
#
# This example shows that it is not very uneconimical of building
# parallel classtrees
module A
  def x
    puts "I'm A.x"
  end

  def w
    puts "I'm A.w"
  end
end

module B
  include A

  def y
    puts "I'm B.y"
  end

  def w
    puts "I'm B.w"
    super # if B is included in a class the super will NO LONGER be A!!!!
  end
end

class C1
  include A

  def w
    puts "I'm C1.w!!, calling super now"
    super
  end

  def f
    puts "C1::f ->"
    x
    w
  end
end

class C2 < C1
  include B

  def f
    puts "C2::f ->"
    x
    y
    w  # B.w since B is included below C1.
  end
end

class C3
  include B

  def f
    puts "C3::f ->"
    x
    y
    w
  end
end

C1.new.f     #   -> A.x  C1.w[A.w]
C2.new.f     #   -> A.x B.y B.w[C1.w[A.w]]
C3.new.f     #   -> A.x B.y B.w[A.w]
puts C2.ancestors.inspect       # -> C2, B, C1, A
puts C3.ancestors.inspect       # -> C3, B, A

__END__

