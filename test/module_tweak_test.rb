
module X
    def g
      puts 'X.g'
    end

    def f
      puts 'X.f'
    end
end

class C
    def f
      puts 'C.f'
    end
end

c = C.new
c.f
c.class.send(:include,X)
c.g
c.f # C.f, as expected.

# Wow... it really changed C and not the meta.
c2 = C.new
c2.f
c2.g
