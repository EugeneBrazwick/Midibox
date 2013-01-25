
require 'reform/app'

describe "Reform::Widget" do

=begin

This very simple example has severe complications.
At least when run from rspec.
Because we do not want user interaction!
Or better, we must generate it.
=end
  it "should show the widget" do
    ok = false
    Reform.app {
      widget {
	size 320, 240
	title 'Top-level widget'
	shown do
	  #tag "SHOWN CALLED!!!!!!!!!!, ok=#{ok}, size = #{size.inspect}" 
	  size.should == [320, 240]	# SPURIOUS SEGV at end...
	  title.should == 'Top-level widget' # IDEM
	  ok = true 
	  # now break from the eventloop, so rspec gets control back
	  $app.quit
	end # shown
      } # widget
    } # app
    ok.should == true
  end # it

  it "should set up a clean parent-children tree" do
    Reform.app {
      widget {
	name :peteWidget
	# break from the eventloop immediately!
	shown { $app.quit }
      }
      # avoid calling it more than once so the trace remains clean:
      pete = peteWidget
      #tag "calling #{pete}::parent(), parent=#{pete.parent}"
      self.should == $app # OK
      pete.parent.should == self # OK
      children.should == [pete]
    }
  end # it

  it "should accept a lambda for a signal handler" do
    shown_it = false
    Reform.app {
      widget {
	shown -> { shown_it = true; $app.quit }
      }
    } # app
    shown_it.should == true
  end

end # describe

