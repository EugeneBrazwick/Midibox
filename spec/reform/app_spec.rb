
require_relative '../../lib/reform/app'

describe "Reform::Application" do
  it "should not hang on an empty app (no eventloop)" do
    expect {
      Reform.app {
      } # app
    }.to_not raise_error
  end # it

  it "should emit the 'created' signal" do
    $created = false
    Reform.app {
      widget shown: -> { $app.quit }
      created { $created = true }
    } # app
    $created.should == true
  end # it

end

