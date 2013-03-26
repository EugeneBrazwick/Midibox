
require 'reform/app'

describe "Reform::Slider" do
  it "should change the model when moved" do
    Reform.app {
      fail_on_errors true
      slider {
	collectnames true
	#trace_propagation true
	rubydata {
	  data 0.0
	  name 'thedata'
	} # rubydata
	connector :self
	size 40, 200
	shown do
	  valueF 0.5
	  #tag "thedata = #{thedata.inspect}"
	  thedata.instance_variable_get(:@rubydata_node).should == 0.5
	  $app.quit
	end
      } 
    } # app
  end # it
end # describe
