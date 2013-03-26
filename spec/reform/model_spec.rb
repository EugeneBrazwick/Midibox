
require 'reform/app'

describe "R::Qt::Data" do

  TITLE = 'modeldata for title'

  it "connects to data stored elsewhere" do
    Reform::app {
      fail_on_errors true
      data TITLE
      widget {
	name 'bert'
	title connector: :self 
	shown do 
	  #STDERR.puts "title=#{title.inspect}"
	  title.should == TITLE 
	  $app.quit 
	end
      }
      # at this point, the app has not been completely setup yet
      bert.title.should == '' 
    }
  end # it

  it "connects to data stored elsewhere, but not out of order" do
    $example = self
    Reform::app {
      fail_on_errors true
      widget {
	name 'bert'
	title {
	  $example.expect { connector :self }.to $example.raise_error Reform::Error
	}
	shown { $app.quit }
      } # widget
      data TITLE
      bert.title.should == '' 
    } # app
  end # it

  it "you cannot create more than 1 model in any control" do
    expect {
      Reform::app {
	fail_on_errors true
	data TITLE
	data TITLE
      }
    }.to raise_error Reform::Error
  end # it

end # describe
