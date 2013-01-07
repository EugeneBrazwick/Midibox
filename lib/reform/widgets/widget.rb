module R::Qt
  class Widget < Object
  end
end

if File.basename($0) == 'rspec'
  include R
  describe "Qt::Widget" do
  end
end # rspec

