
require 'reform/app'

describe "Reform::LineEdit" do

  it "should connect to a model" do
    Reform.app {
      data 'Hallo World'
      widget {
	size 320, 240
	title 'Top-level widget'
#	shown { $app.quit }
	edit {
	  text connector: :self
	}
	# 'edit' understands that 'connector' refers to the content attribute 'text'
	edit connector: :self
      } # widget
    } # app
  end # it

end # describe

