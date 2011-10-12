
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

describe :ComboBox do
  before do
    Reform::app { 
      giveIt200ms 
      combo {
	name :combo
	struct 'avanare', 'resu', 'illuve', 'atarie', 'olme'
      }
    }
  end

  after do
    $qApp.exec
  end

  it 'should display the items in the combobox' do
    qcombo = $qApp.firstform.combo.qtc
    #tag "qcombo=#{qcombo}"
    qcombo.count.should == 5
    qcombo.itemText(0).should == 'avanare'
    qcombo.itemText(3).should == 'atarie'
  end
end # describe

class MySender
  def track_propagation; $VERBOSE; end
end

describe 'combobox with hash:' do
  before do
    Reform::app { 
      giveIt200ms 
      struct global_key: :key1
      combo {
	name :combo
	struct key1: 'avanare', key2: 'what?', v: 'illuve', w: 'atarie', nasdaq: 'olme'
	connector :global_key
	# the value of connector is itself the key:
	key_connector :self
      }
    }
  end

  after do
    $qApp.exec
  end

  it 'should display the items in the combobox' do
    qcombo = $qApp.firstform.combo.qtc
    #tag "qcombo=#{qcombo}"
    qcombo.count.should == 5
    qcombo.itemText(0).should == 'avanare'
    qcombo.itemText(3).should == 'atarie'
  end

  example 'changing the model should change the current index' do
    qcombo = $qApp.firstform.combo.qtc
    $qApp.model.global_key.should == :key1
    sender = MySender.new
    $qApp.model.transaction(sender) do 
      $qApp.model.global_key = :key2
    end
    qcombo.currentIndex.should == 1
    qcombo.currentText.should == 'what?'
  end

  example 'changing the index should change the model' do
    qcombo = $qApp.firstform.combo.qtc
    $qApp.model.global_key.should == :key1
    qcombo.currentIndex.should == 0
    qcombo.activated(1)
    $qApp.model.global_key.should == :key2
  end
end # describe

