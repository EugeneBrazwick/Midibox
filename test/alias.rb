
# Q : if you override method, does alias go with it?

class A
  def f
    puts 'f'
  end

  alias :g :f

end

class B < A
  def f
    puts 'B::f'
  end
end

a = B.new
a.f # -> 'B::f'
a.g # -> 'f'

# A: NO!!, and it was obvious since 'alias' can be used to create 'original' calls.
