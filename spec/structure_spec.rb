
require 'reform/app'
require 'reform/models/structure'

module Reform
  # this observer 'records' the change it sees
  class MyObserver < Qt::Object

    def updateModel model, propa
      @model, @propa = model, propa
    end

    attr :model, :propa
  end
end

include Reform

describe Structure do

  it "can be constructed as a simple hash value" do
    # s = Structure.new key: 5			But beware of conflicts with Hash methods.
    # in this case 'Hash#key' !
    # This does not mean it fails, but 's.key' can no longer be used
    s = Structure.new value: 5
    # the only possible attribute is self
#     tag "s = #{s.inspect}"
    s.model_apply_getter(:value).should == 5
    s.model_apply_setter(:value, 4)
    s.model_apply_getter(:value).should == 4
    s[:value].should == 4
  end

  it "can be constructed as a simple array value" do
    s = Structure.new [5, :whoof, :skreek, 'bla']
    s.model_apply_getter(0).should == 5
    s.model_apply_setter(2, 4)
    s.model_apply_getter(2).should == 4
    s[2].should == 4
  end

  it "methods can be used to access a hash value" do
    s = Structure.new text: "Hallo world"
    s.text.should == 'Hallo world'
  end

  it "should rollback simple transactions" do
    s = Structure.new value: "Hallo world"
    s.value.should == 'Hallo world'
    s.transaction do |tran|
#       tag "assigning 'oops' to self"
      s.value = 'oops'
      s.value.should == 'oops'
#       tag "CALLING rollback"
      tran.rollback
#       tag "s is now #{s.inspect}"
      s.value.should == "Hallo world"
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
    # the new Structure class no longer meddles and it already works for
    # Array and Hash. However, it returns tuples k,v for the Hash which is
    # incompatible with the old solution
    s.each_with_index do |(key, el), i|
      #tag "el=#{el}, i = #{i.inspect}"
      i.should >= 0 && i.should < 4
      case i
      when 0 
	el.should == 24 
	key.should be(:a)
      when 1 then el.should == 345
      when 2 then el.should == 'hallo'
      when 3 then el.should == 'world'
      end
    end
  end

  it "should collect changes and report these when the tran is committed" do
    s = Structure.new a: 24, b: 345, c: 'hallo', d: 'world'
    o = MyObserver.new
    s.parent = o
    s.parent.should == o
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
    # the new Structure class MUST be a hash. Other stuff is contrived
    s = Structure.new value: [24, 80, 'hallo', :world, true]
    t = s.value
    t[2].should == 'hallo'
    t[2] = 81
    t[2].should == 81
  end

  it "should allow deep recursion" do
    t = Structure.new x: 24, y: 'hallo', z: { a: 23, b: 'world', c: { d: 'even deeper' } }
    t.x.should == 24
    t.z.b.should == 'world'
    t.z.c.d.should == 'even deeper'
    t.z.c.d = 'pindakaas'
    t.z.c.d.should == 'pindakaas'
    t = Structure.new x: 24, y: [23, 'hallo', {i: :interesting}]
    t.y.should be_a(RStoreNode)
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
    t.z.should be_a(RStoreNode)
    t.z.c.should be_a(RStoreNode)
    t = Structure.new value: [23, 'hallo', { a: 23, b: 'world', c: { d: 'even deeper' } }]
    t.value[2].should be_a(RStoreNode)
    t.value[2].c.should be_a(RStoreNode)
    t = Structure.new x: 23, y: 'hallo', c: [23, 'world', 'even deeper' ]
    t.c.should be_a(RStoreNode)
  end

  it "should collect more complicated changes" do
    s = Structure.new x: 24, y: [23, 'hallo', {i: :interesting}]
    o = MyObserver.new
    s.parent = o
    s.transaction do
      #tag "inside test transaction"
      s.x *= 2
      s.y[2] = {i: :strange, j: 'one more key'}
      s.y[2].j = 88
    end
    # attr_index is the record of the changed indexpaths.
    # Each path is an array of keys that should be applied chainlike on the model.
    # So  [:a, 323, :b] as key indicates that s.a[323].b  has been altered
    (keys = o.propa.keypaths.keys).should == [[:x], [:y, 2], [:y, 2, :j]]
    (pc = o.propa.keypaths[keys[2]]).should be_a Transaction::PropertyChange
    #tag "pc for .y[2].j = #{pc}"
    pc.key.should == [:j]
    pc.oldval.should == 'one more key'
    (pc = o.propa.keypaths[keys[1]]).should be_a Transaction::PropertyChange
    #tag "pc for .y[2] = #{pc}"
    pc.key.should == [2]
    pc.oldval.should == {i: :interesting}
  end

  it "should shortcut splices" do
    s = Structure.new value: [1, 2, 3, 4, 5, 6]
    v = s.value
    v[3, 2] = 1
    v.should == [1, 2, 3, 1, 6]
    s.transaction do |tran|
      v[1, 2] = 27
      v.should == [1, 27, 1, 6]
      tran.abort
    end
    v.should == [1, 2, 3, 1, 6]
  end

  it "should shortcut splices on deeper levels" do
    s = Structure.new x: 1, y: 2, z: [3, 4, 5, 6]
    s.z[2, 5] = 'hall', 'o', 'worl', 'd'
    s[:x].should == 1
    s[:y].should == 2
    s[:z].should be_a(RStoreNode)
    s[:z].should == [3, 4,  'hall', 'o', 'worl', 'd']
    s.z[1].should == 4
    s.transaction do |tran|
      s.z[2, 4] = []
      s[:x].should == 1
      s.y.should == 2
      s.z.should == [3, 4]
      tran.abort
    end
    s.x.should == 1
    s[:y].should == 2
    s.z.should be_a(RStoreNode)
    s.z.should == [3, 4,  'hall', 'o', 'worl', 'd']
    s.z[1].should == 4
  end

  it "should recognize a replacement when it sees one" do
    s = Structure.new value: [1, 2, 3, 4]
    v = s.value # let's be wise
    s.transaction do |tran|
      v.map! { |x| x * 2 }
      v.should be_a(RStoreNode)
      v[0].should == 2
      v.should == [2, 4, 6, 8]
      tran.abort
    end
    v.should == [1, 2, 3, 4]
    s.value.should == [1, 2, 3, 4]
  end

  it "should wrap around ordinary instances" do
    class Fluffy
      attr_accessor :whoof

      def bark
        puts whoof || 'whoof'
      end

    end
    fluffy = Fluffy.new
    s = Structure.new fluffy: fluffy
    fluffy = s.fluffy
    fluffy.bark
    fluffy.whoof = 'skreek skreek'
    fluffy.bark
  end

  it "should work correctly with appending" do
    s = Structure.new value: [1, 2, 3, 4]
    v = s.value
    v.respond_to?(:<<).should == true
#     tag "CALLING #{s.class}#<<"
    v << 5
#     tag "CALLED #{s.class}#<<"
    v.should == [1,2,3,4,5]
    v.push(6, 7)
    v.should == [1,2,3,4,5,6,7]
    s = Structure.new value: [1, 2, 3, 4]
    v = s[:value]
    s.transaction do |tran|
      v << 5
      v.should == [1,2,3,4,5]
      v.push(6, 7)
      v.should == [1,2,3,4,5,6,7]
      tran.abort
    end
    v.should == [1,2,3,4]
  end

  it "should work correctly with pop" do
    s = Structure.new value: [1, 2, 3, 4]
    v = s.value
    v.pop
    v.should == [1,2,3]
    v.transaction do |tran|
      v.pop
      tran.abort
    end
    v.should == [1,2,3]
  end

  it "should work correctly with insert" do
    s = Structure.new value: [1, 2, 3, 4]
    v = s.value
    v.insert(2, 24)
    v.should == [1,2,24,3,4]
    v.insert(-1, 23, 22)
    v.should == [1,2,24,3,4,23,22]
    v.transaction do |tran|
      v.insert(2, 244, 233)
      v.insert(-3, 2313)
      tran.abort
    end
    v.should == [1,2,24,3,4,23,22]
  end

  it "should work correctly with delete_at" do
    s = Structure.new value: [1, 2, 3, 4, 5, 6]
    v = s[:value]
    v.delete_at(3)
    v.should == [1, 2, 3, 5, 6]
    v.transaction do |tran|
      v.delete_at(-2)
      v.should == [1, 2, 3, 6]
      tran.abort
    end
    v.should == [1, 2, 3, 5, 6]
  end

  it "should work correctly with delete" do
    s = Structure.new a: 1, b: 2, c: 3, d: 4,  e: 5
    s.delete(:b)
    s.should == { a: 1, c: 3, d: 4, e: 5 }
    s.transaction do |tran|
      s.delete(:c)
      s.should == { a: 1, d: 4, e: 5 }
      tran.abort
      s.should == { a: 1, c: 3, d: 4, e: 5 }
    end
  end

  it "should shift properly" do
    s = Structure.new exy: [1, 2, 3, 4, 5]
    v = s.exy
    v.shift
    v.should == [ 2, 3, 4, 5]
    v.unshift(-2)
    v.should == [ -2, 2, 3, 4, 5]
    v.transaction do |tran|
      v.unshift(34, 344, 3444)
      v.should == [ 34, 344, 3444, -2, 2, 3, 4, 5]
      v.shift(6)
      v.should == [4, 5]
      tran.abort
      v.should == [ -2, 2, 3, 4, 5]
    end
  end
end
