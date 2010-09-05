require 'spec'

require_relative '../lib/rstore/rstore'

class Test
  private
  def initialize
    @text = 'Hallo world'
  end
  public
  attr :text
end  #class Test

describe RStore do

  it 'should store data between ruby invocations' do
    t = Test.new
    RStore.make_persistent t
    fork do
      t2 = RStore.load
      t2.text.should == 'Hallo world'
    end
    Process.wait
  end # it

end # describe RStore
