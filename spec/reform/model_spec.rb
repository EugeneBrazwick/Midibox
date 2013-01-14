
require 'reform/app'

describe "R::Qt::Data" do

  TITLE = 'modeldata for title'

  it "connects to data stored elsewhere" do
    Reform::app {
      data TITLE
      widget {
	name 'bert'
	title connector: :self 
	shown { $app.quit }
      }
      bert.title.should == TITLE 
    }
  end # it

  it "connects to data stored elsewhere, but not out of order" do
    $example = self
    Reform::app {
      widget {
	name 'bert'
	title {
	  $example.expect { connector :self }.to $example.raise_error Reform::Error
	}
	shown { $app.quit }
      } # widget
      bert.title.should == '' 
    } # app
  end # it
end # describe
