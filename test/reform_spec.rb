
# this requires rspec:                  sudo gem install rspec
# docs: http://rspec.info/
# spec does not need these, but rcov does!
require 'reform/app'
require 'reform/widget'

include Reform

class App
  def giveIt200ms
    doNotRun true
    timer = Qt::Timer.new($qApp)
    connect(timer, SIGNAL('timeout()'), $qApp, SLOT('quit()'))
    timer.start(200)
  end
end

describe App do
  before do
    Reform::app {
      giveIt200ms
    }
  end

  it 'should just work' do
    ->{$qApp.exec}.should_not raise_exception
  end

end # App

describe Frame do
  before do
#     tag "calling app"
    Reform::app {
#       tag "GIVE IT 200ms"
      giveIt200ms
#       tag "calling edit"
      edit { name :myEdit }
    }
  end
  after { $qApp.exec }

  it 'should have a form' do
    $qApp.firstform.should_not be_nil
    $qApp.firstform.should == $qApp.all_forms[0]
  end

  it 'should see the edit control' do
#     tag "DOES THIS SHOW?"
    $qApp.firstform.should respond_to :myEdit
    # reform now uses 'Qt::Object#objectName' which returns a string
    $qApp.firstform.myEdit.objectName.should == 'myEdit'
    # however, 'name' returns the original symbol
    $qApp.firstform.myEdit.name.should == :myEdit
  end

  it 'should have created a formlayout and reparented edit' do
#     tag "children = #{$qApp.firstform.children.map {|c| c.class }.inspect}"
    $qApp.firstform.children.length.should == 1
    layout = $qApp.firstform.children[0]
    layout.class.should == FormLayout
    layout.children.length.should == 1
    layout.children[0].class.should == Edit
  end
end # Frame

describe 'MenuBar' do

  before do
    Reform::app {
      giveIt200ms
      menuBar {
        menu {
          title '&File'
          action {
            label '&Open ...'
            whenTriggered { @triggered = true }
            name :openAct
          }
        }
      }
    }
  end

  after { $qApp.exec }

  it 'should run properly' do
  end

  it 'should call the trigger callback' do
    form = $qApp.firstform
    class << form
       attr :triggered
    end
    form.triggered.should == nil
    form.openAct.whenTriggered
    form.triggered.should == true
  end
end