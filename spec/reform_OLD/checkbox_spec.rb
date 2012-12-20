
# Copyright (c) 2011 Eugene Brazwick

require 'reform/app'

include Reform

class App
  def giveIt200ms
    doNotRun true
    timer = Qt::Timer.new($qApp)
    connect(timer, SIGNAL('timeout()'), $qApp, SLOT('quit()'))
    timer.start(200)
  end
end

class MySender
  def track_propagation; $VERBOSE; end
end

describe :CheckBox do
  before do
    Reform::app { 
      giveIt200ms 
      struct some_bool: true, other_bool: false
      checkbox {
	name :cb_1
	connector :some_bool
      }
      checkbox {
	name :cb_2
	connector :other_bool
      }
    }
  end

  after do
    $qApp.exec
  end

  it 'should be using the model' do
    qcheckbox1 = $qApp.firstform.cb_1.qtc
    qcheckbox2 = $qApp.firstform.cb_2.qtc
    qcheckbox1.checked?.should == true 
    qcheckbox2.checked?.should == false 
  end

  example 'changing the model should change the current index' do
    qcheckbox1 = $qApp.firstform.cb_1.qtc
    qcheckbox1.checked?.should == true 
    $qApp.model.transaction(MySender.new) do 
      $qApp.model.some_bool = false
    end
    qcheckbox1.checked?.should == false 
  end

  example 'changing the checked state should change the model' do
    qcheckbox1 = $qApp.firstform.cb_1.qtc
    $qApp.model.some_bool.should == true
    qcheckbox1.clicked(false)
    $qApp.model.some_bool.should == false
    qcheckbox1.clicked(true)
    $qApp.model.some_bool.should == true
  end
  
  example 'toggling the checked state should change the model' do
    qcheckbox1 = $qApp.firstform.cb_1.qtc
    $qApp.model.some_bool.should == true
    qcheckbox1.clicked(false)
    $qApp.model.some_bool.should == false
    qcheckbox1.toggle
    $qApp.model.some_bool.should == true
  end
end # describe



