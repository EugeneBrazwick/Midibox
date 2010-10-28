
require 'rstore/rstore'

class TestMe
  private
    def initialize
      @text = 'Hallo world'
    end
  public
    attr :text
end  #class TestMe

describe RStore do

=begin   NICE ONE,  but RStore is still VAPORWARE!!!
  it 'should store data between ruby invocations' do
    t = Test.new
    RStore.make_persistent t
    fork do
      t2 = RStore.load
      t2.text.should == 'Hallo world'
    end
    Process.wait
  end # it
=end

end # describe RStore
