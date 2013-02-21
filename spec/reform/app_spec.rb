
require_relative '../../lib/reform/app'

describe 'Qt::Application' do
  it "should not hang on an empty app (no eventloop)" do
    expect {
      Reform.app {
	fail_on_errors true
      } # app
    }.to_not raise_error
  end # it

  it "should emit the 'created' signal" do
    $created = false
    Reform.app {
      fail_on_errors true
      widget shown: -> { $app.quit }
      created { $created = true }
    } # app
    $created.should == true
  end # it

end

