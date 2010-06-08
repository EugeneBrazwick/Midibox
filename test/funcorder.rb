class C

  def f arg
	puts "f called"
        arg
  end

  def g arg = nil
	puts "g called"
        method :g
  end

  def h arg = nil
	puts "h called"
        method :f
  end

  def apply
	f g h    # == f(g h)
  end

  def apply1
     f (g h)
  end

  def apply2
    (f g)[h]  # cannot use (f g)(h) since 'f g' is a Method really
  end
end;

c = C.new
c.apply  # =>  h called, g called, f calledks
c.apply1 # => ""
c.apply2 # => g, f, h then g(!)