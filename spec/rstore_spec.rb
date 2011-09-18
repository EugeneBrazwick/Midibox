
require 'reform/app'
require 'reform/models/rstore'

class TestMe
  private
    def initialize
      @text = 'Hallo world'
    end
  public
    attr_accessor :text
end  #class TestMe

include Reform

describe RStore do

  before :all do
    @dbname = '/tmp/rstore_test.dbm'
  end
  
  it 'should store data between ruby invocations' do
    t = TestMe.new
    RStore.new(@dbname) do |rstore|
      rstore.t = t
    end
    # fork do   rspec doesn't like fork
#     tag "Reopen test"
    RStore.new(@dbname) do |rstore|
#       tag "read key 't'"
      t = rstore.t
#       tag "t = #{t.inspect}"
      # I don't know if 'class' can be tweaked like this....
      # Can we alter TestMe to become an RStoreNode somehow??
      t.class.should == TestMe
      t.instance_of?(TestMe).should == true
      (TestMe === t).should == true
      (RStoreNode === t).should == true
      t.text.should == 'Hallo world'
    end
  end # it

  it 'should be contagious' do
    RStore.new(@dbname) do |rstore|
      rstore.t = TestMe.new
    end
    RStore.new(@dbname) do |rstore|
      t = rstore.t
      t.model_root.should == rstore
      # t is 'contaminated'. Changes to it are also saved to disk!
#       tag "overwriting t.text"
      t.text = 'Not at all weird'
#       tag "OK maybe"
    end
    RStore.new(@dbname) do |rstore|
      t = rstore.t
      t.text.should == 'Not at all weird'
    end
  end

  it "should accept hashes" do
    RStore.new(@dbname) do |rstore|
      rstore.t = { a: 24, b: 345, c: 'hallo', d: 'world' }
    end
    RStore.new(@dbname) do |rstore|
      s = rstore.t
      (RStoreNode === s).should == true
      s.b.should == 345
      s.b = 'something completely different'
      s.b.should == 'something completely different'
    end
    RStore.new(@dbname) do |rstore|
      rstore.t.b.should == 'something completely different'
    end
  end

  it "should rollback simple transactions" do
    RStore.new(@dbname) do |rstore|
      rstore.t = 'Hallo world'
      rstore.transaction do |tran|
        rstore.t = 'oops'
        tran.rollback
        rstore.t.should == 'Hallo world'
      end
    end
    # even more, the change should not be saved
    RStore.new(@dbname ) do |rstore|
      rstore.t.should == 'Hallo world'
    end
  end

  class MyObserver

    def updateModel model, propa
      @model, @propa = model, propa
    end

    attr :model, :propa
  end

  it "should collect changes and report these when the tran is committed" do
    RStore.new(@dbname) do |rstore|
      # FEATURE: what gets out, is not what is put in!!
#       s = rstore.s = { a: 24, b: 345, c: 'hallo', d: 'world' }
      rstore.s = { a: 24, b: 345, c: 'hallo', d: 'world' }
      s = rstore.s
      o = MyObserver.new
      rstore.model_parent = o
      rstore.model_parent.should == o
      s.transaction do
        s.a = 184
        s.c = 'ohayou'
        s.d = 'kono sekai'
      end
      o.propa.should be_a Propagation
      # attr_index is the record of the changed indexpaths.
      # Each path is an array of keys that should be applied chainlike on the model.
      # So  [:a, 323, :b] as key indicates that s.a[323].b  has been altered
      (keys = o.propa.keypaths.keys).should == [[:s, :a], [:s, :c], [:s, :d]]
      (propchange = o.propa.keypaths[keys[0]]).should be_a Transaction::PropertyChange
      propchange.key.should == [:a]
      propchange.oldval.should == 24
      o.propa.keypaths[keys[1]].oldval == 'hallo'
      o.propa.keypaths[keys[2]].oldval == 'world'
    end
  end

  it "should be possible to abort hash changes" do
    RStore.new(@dbname) do |rstore|
      rstore.s = { a: 24, b: 345, c: 'hallo', d: 'world' }
      s = rstore.s
      s.transaction do |tran|
        # IMPORTANT (but trivial). You cannot assign 's' as is.
        # we cannot catch such things since what's happening is you assign
        # to a local variable, and not to the 'RStore'.
        s.a = 184
        s.c = 'ohayou'
        s.d = 'kono sekai'
        s.should == { a: 184, b: 345, c: 'ohayou', d: 'kono sekai' }
        tran.abort
      end
      s.should == { a: 24, b: 345, c: 'hallo', d: 'world' }
    end
    RStore.new(@dbname) do |rstore|
      rstore.s.should == { a: 24, b: 345, c: 'hallo', d: 'world' }
    end
  end

  it "should wrap around arrays" do
    RStore.new(@dbname) do |rstore|
      rstore.s = [24, 80, 'hallo', :world, true]
      s = rstore.s
      s[2].should == 'hallo'
      s[2] = 81
      s[2].should == 81
      s.should == [24, 80, 81, :world, true]
    end
    RStore.new(@dbname) do |rstore|
      s = rstore.s
      s[2].should == 81
      s.should == [24, 80, 81, :world, true]
    end
  end

  it 'should follow Array splicing habits' do
     # we can replace elements that do not exist
    RStore.new(@dbname) do |rstore|
      rstore.s = [24, 80, 'hallo', :world, true]
      s = rstore.s
      s.transaction do |tran|
        s[2..99] = [33, 'mi mi mi do']
        s.should == [24, 80, 33, 'mi mi mi do']
        tran.abort
      end
      s.should == [24, 80, 'hallo', :world, true]
    end
    RStore.new(@dbname) do |rstore|
      rstore.s = [24, 80, 'hallo', :world, true]
      s = rstore.s
      # we can replace elements that do not exist
      s[2..99] = [33, 'mi mi mi do']
      s.should == [24, 80, 33, 'mi mi mi do']
     end
    RStore.new(@dbname) do |rstore|
      s = rstore.s
      s.should == [24, 80, 33, 'mi mi mi do']
    end
  end

  it 'should insert implicit nils' do
    RStore.new(@dbname) do |rstore|
      rstore.s = [24, 80]
      s = rstore.s
      s.transaction do |tran|
        s[5, 0] = ['hallo', nil, 'mi mi mi do']
        s.should == [24, 80, nil, nil, nil, 'hallo', nil, 'mi mi mi do']
        tran.abort
      end
      s.should == [24, 80]
    end
    RStore.new(@dbname) do |rstore|
      rstore.s = [24, 80]
      s = rstore.s
      s.transaction do |tran|
        s[5, 99] = ['hallo', nil, 'mi mi mi do']
      end
      s.should == [24, 80, nil, nil, nil, 'hallo', nil, 'mi mi mi do']
    end
    RStore.new(@dbname) do |rstore|
      s = rstore.s
      s.should == [24, 80, nil, nil, nil, 'hallo', nil, 'mi mi mi do']
    end
  end
  
  it 'should be able to handle nested arrays' do
    RStore.new(@dbname) do |rstore|
      rstore.s = [24, 80]
      s = rstore.s
      s.transaction do |tran|
        s[5] = ['hallo', nil, 'mi mi mi do']
      end
      s.should == [24, 80, nil, nil, nil, ['hallo', nil, 'mi mi mi do']]
    end
  end
end # describe RStore

__END__

RSTORE
============================
DESIGN
----------------------------

Same as structure.rb
But everything is stored in a keyvalue (pe kyoto tycoon) database.

We need
  - oids. Next oid to use is stored in 'oid' key.
  - root. By definition oid = 0. This is a hash wrap.
  - hashes are internalized by using marshalling. However non-simple keys
      are stored recursively by assigning them an oid.
      Also the attribute is suffixed with '_oid'.
      So when read, if a hash key is name '*_oid' we must strip oid and lookup the value.
      Of course we do this lazily, using method_missing
  - arrays are stored similarly, but complex nodes are stored as Oid class (wrapper).
  - objects. Objects are treated similar to hashes.
  - garbage collection.  Some nodes may be unreachable from the root. Since it is hard
    to track which oids are used by a program, and which can safely be deleted.

When structures are read the oid must be stored in them.
RStoreNode must forward to wrapped classes.  Unlike structure we must catch all updates.
So the oids can be stored in the RStoreNodes.
It may also be that we must inherit from RStoreNode. That is much less tricky.
