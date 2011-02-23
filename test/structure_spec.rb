
require 'reform/app'
require 'reform/models/structure'

include Reform

describe Structure do

  it "can be constructed as a simple value" do
    s = Structure.new 5
    # the only possible attribute is self
#     tag "s = #{s.inspect}"
    s.model_apply_getter(:self).should == 5
    s.model_apply_setter(:self, 4)
    s.model_apply_getter(:self).should == 4
  end

  it "self should work as method to access the value" do
    s = Structure.new "Hallo world"
    s.self.should == 'Hallo world'
  end

  it "should rollback simple transactions" do
    s = Structure.new "Hallo world"
    s.self.should == 'Hallo world'
    s.transaction do |tran|
#       tag "assigning 'oops' to self"
      s.self = 'oops'
      s.self.should == 'oops'
#       tag "CALLING rollback"
      tran.rollback
#       tag "s is now #{s.inspect}"
      s.self.should == "Hallo world"
    end
  end

  it "should accept hashes" do
    s = Structure.new a: 24, b: 345, c: 'hallo', d: 'world'
    s.b.should == 345
    s.b = 'something completely different'
    s.b.should == 'something completely different'
  end

  # this makes a hash compitable with Qt::ModelIndex which has integers for rows and columns
  it "should iterate hashes over a virtual integer key" do
    s = Structure.new a: 24, b: 345, c: 'hallo', d: 'world'
    s.each_with_index do |el, i|
#       tag "el=#{el}, i = #{i.inspect}"
      i.should >= 0 && i.should < 4
      case i
      when 0 then el.should == 24
      when 1 then el.should == 345
      when 2 then el.should == 'hallo'
      when 3 then el.should == 'world'
      end
    end
  end

  # this observer 'records' the change it sees
  class MyObserver < Qt::Object

    def updateModel model, propa
      @model, @propa = model, propa
    end

    attr :model, :propa
  end

  it "should collect changes and report these when the tran is committed" do
    s = Structure.new a: 24, b: 345, c: 'hallo', d: 'world'
    o = MyObserver.new
    s.model_parent = o
    s.model_parent.should == o
    s.transaction do
      s.a = 184
      s.c = 'ohayou'
      s.d = 'kono sekai'
    end
    o.propa.should be_a Propagation
    # attr_index is the record of the changed indexpaths.
    # Each path is an array of keys that should be applied chainlike on the model.
    # So  [:a, 323, :b] as key indicates that s.a[323].b  has been altered
    (keys = o.propa.keypaths.keys).should == [[:a], [:c], [:d]]
    (pc = o.propa.keypaths[keys[0]]).should be_a Transaction::PropertyChange
    pc.key.should == [:a]
    pc.oldval.should == 24
    o.propa.keypaths[keys[1]].oldval == 'hallo'
    o.propa.keypaths[keys[2]].oldval == 'world'
  end

  it "should be possible to abort hash changes" do
    s = Structure.new a: 24, b: 345, c: 'hallo', d: 'world'
    s.transaction do |tran|
      s.a = 184
      s.c = 'ohayou'
      s.d = 'kono sekai'
      s.model_value.should == { a: 184, b: 345, c: 'ohayou', d: 'kono sekai' }
      tran.abort
      s.model_value.should == { a: 24, b: 345, c: 'hallo', d: 'world' }
    end
  end

  it "should wrap around arrays" do
    s = Structure.new 24, 80, 'hallo', :world, true
    s[2].should == 'hallo'
    s[2] = 81
    s[2].should == 81
  end

  it "should allow deep recursion" do
    t = Structure.new x: 24, y: 'hallo', z: { a: 23, b: 'world', c: { d: 'even deeper' } }
    t.x.should == 24
    t.z.b.should == 'world'
    t.z.c.d.should == 'even deeper'
    t.z.c.d = 'pindakaas'
    t.z.c.d.should == 'pindakaas'
    t = Structure.new x: 24, y: [23, 'hallo', {i: :interesting}]
    t.y.should be_a(Structure)
    t.y[1].should == 'hallo'
    t.y[2].i.should == :interesting
    t.transaction do |tran|
      t.y[2].i = :not
      t.y[2].i.should == :not
      tran.abort
      t.y[2].i.should == :interesting
    end
  end

  it "structures should be contagious" do
    t = Structure.new x: 24, y: 'hallo', z: { a: 23, b: 'world', c: { d: 'even deeper' } }
    t.z.class.should == Structure
    t.z.c.class.should == Structure
    t = Structure.new 23, 'hallo', { a: 23, b: 'world', c: { d: 'even deeper' } }
    t[2].class.should == Structure
    t[2].c.class.should == Structure
    t = Structure.new x: 23, y: 'hallo', c: [23, 'world', 'even deeper' ]
    t.c.class.should == Structure
  end

  it "should collect more complicated changes" do
    s = Structure.new x: 24, y: [23, 'hallo', {i: :interesting}]
    o = MyObserver.new
    s.model_parent = o
    s.transaction do
      s.x *= 2
      s.y[2] = {i: :strange, j: 'one more key'}
      s.y[2].j = 88
    end
    # attr_index is the record of the changed indexpaths.
    # Each path is an array of keys that should be applied chainlike on the model.
    # So  [:a, 323, :b] as key indicates that s.a[323].b  has been altered
    (keys = o.propa.keypaths.keys).should == [[:x], [:y, 2], [:y, 2, :j]]
    (pc = o.propa.keypaths[keys[2]]).should be_a Transaction::PropertyChange
    pc.keypath.should == [:y, 2, :j]
    pc.oldval.should == 'one more key'
    (pc = o.propa.keypaths[keys[1]]).should be_a Transaction::PropertyChange
    pc.keypath.should == [:y, 2]
    pc.oldval.value.should == {i: :interesting}
  end

  it "should shortcut splices" do
    s = Structure.new 1, 2, 3, 4, 5, 6
    s[3, 2] = 1
    s.value.should == [1, 2, 3, 1, 6]
    s.transaction do |tran|
      s[1, 2] = 27
      s.value.should == [1, 27, 1, 6]
      tran.abort
      s.value.should == [1, 2, 3, 1, 6]
    end
  end

  it "should shortcut splices on deeper levels" do
    s = Structure.new x: 1, y: 2, z: [3, 4, 5, 6]
    s.z[2, 5] = 'hall', 'o', 'worl', 'd'
    s.value[:x].should == 1
    s.value[:y].should == 2
    s.value[:z].should be_a(Structure)
    s.value[:z].value.should == [3, 4,  'hall', 'o', 'worl', 'd']
    s.z[1].should == 4
    s.transaction do |tran|
      s.z[2, 4] = []
      s.value[:x].should == 1
      s.value[:y].should == 2
      s.value[:z].value.should == [3, 4]
      tran.abort
      s.value[:x].should == 1
      s.value[:y].should == 2
      s.value[:z].should be_a(Structure)
      s.value[:z].value.should == [3, 4,  'hall', 'o', 'worl', 'd']
      s.z[1].should == 4
    end
  end

  it "should recognize a replacement when it sees one" do
    s = Structure.new 1, 2, 3, 4
    s.transaction do |tran|
      s.map! { |x| x * 2 }
      s.value.should == [2, 4, 6, 8]
      tran.abort
      s.value.should == [1, 2, 3, 4]
    end
  end

  it "should wrap around ordinary instances" do
    class Fluffy
      attr_accessor :whoof

      def bark
        puts whoof || 'whoof'
      end

    end
    fluffy = Fluffy.new
    s = Structure.new(fluffy)
    s.bark
    s.whoof = 'skreek skreek'
    s.bark
  end

  it "should work correctly with appending" do
    s = Structure.new 1, 2, 3, 4
    s.respond_to?(:<<).should == true
#     tag "CALLING #{s.class}#<<"
    s << 5
#     tag "CALLED #{s.class}#<<"
    s.value.should == [1,2,3,4,5]
    s.push(6, 7)
    s.value.should == [1,2,3,4,5,6,7]
    s = Structure.new 1, 2, 3, 4
    s.transaction do |tran|
      s << 5
      s.value.should == [1,2,3,4,5]
      s.push(6, 7)
      s.value.should == [1,2,3,4,5,6,7]
      tran.abort
    end
    s.value.should == [1,2,3,4]
  end

  it "should work correctly with pop" do
    s = Structure.new 1, 2, 3, 4
    s.pop
    s.value.should == [1,2,3]
    s.transaction do |tran|
      s.pop
      tran.abort
    end
    s.value.should == [1,2,3]
  end

  it "should work correctly with insert" do
    s = Structure.new 1, 2, 3, 4
    s.insert(2, 24)
    s.value.should == [1,2,24,3,4]
    s.insert(-1, 23, 22)
    s.value.should == [1,2,24,3,4,23,22]
    s.transaction do |tran|
      s.insert(2, 244, 233)
      s.insert(-3, 2313)
      tran.abort
    end
    s.value.should == [1,2,24,3,4,23,22]
  end

  it "should work correctly with delete_at" do
    s = Structure.new 1, 2, 3, 4, 5, 6
    s.delete_at(3)
    s.value.should == [1, 2, 3, 5, 6]
    s.transaction do |tran|
      s.delete_at(-2)
      s.value.should == [1, 2, 3, 6]
      tran.abort
      s.value.should == [1, 2, 3, 5, 6]
    end
  end

  it "should work correctly with delete" do
    s = Structure.new a: 1, b: 2, c: 3, d: 4,  e: 5
    s.delete(:b)
    s.value.should == { a: 1, c: 3, d: 4, e: 5 }
    s.transaction do |tran|
      s.delete(:c)
      s.value.should == { a: 1, d: 4, e: 5 }
      tran.abort
      s.value.should == { a: 1, c: 3, d: 4, e: 5 }
    end
  end

  it "should shift properly" do
    s = Structure.new 1, 2, 3, 4, 5
    s.shift
    s.value.should == [ 2, 3, 4, 5]
    s.unshift(-2)
    s.value.should == [ -2, 2, 3, 4, 5]
    s.transaction do |tran|
      s.unshift(34, 344, 3444)
      s.value.should == [ 34, 344, 3444, -2, 2, 3, 4, 5]
      s.shift(6)
      s.value.should == [4, 5]
      tran.abort
      s.value.should == [ -2, 2, 3, 4, 5]
    end
  end
end