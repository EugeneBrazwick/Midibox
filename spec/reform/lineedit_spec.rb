
require 'reform/app'

describe "Reform::LineEdit" do

  TEXT = 'Hallo World!'

  it "should connect to a model" do
    $quit = false
    Reform.app {
      data TEXT
      widget {
	name :w
	size 320, 240
	title 'Top-level widget'
	shown do 
	  $app.w.e1.text.should == TEXT
	  $app.w.e2.text.should == TEXT
	  $quit = true
	  $app.quit
	end 
	edit {
	  name :e1
	  text connector: :self
	}
	# 'edit' understands that 'connector' refers to the content attribute 'text'
	edit connector: :self, name: :e2
      } # widget
    } # app
    $quit.should == true
  end # it

end # describe

