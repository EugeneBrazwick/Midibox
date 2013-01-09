
require_relative '../../lib/reform/app'

describe "Reform::Application" do
  it "should not hang on an empty app (no eventloop)" do
    expect {
      Reform.app {
      } # app
    }.to_not raise_error
  end
end

