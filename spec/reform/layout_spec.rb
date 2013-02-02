
require 'reform/app'

describe "Reform::Layout" do

  it "should parent as shown, not as done by Qt internally" do
    $shown = false
    Reform.app {
      fail_on_instantiation_errors true
      rubydata data: 'Hallo World', name: 'rdata'
      widget {
	name 'wdgt'
	size 320, 240
	title 'Top-level widget'
  	shown { $shown = true; $app.quit }
	vbox {
	  name 'vbox'
	  edit connector: :self, name: 'edt'
	} # vbox
      } # widget
      $app.should == self

      # this causes a method_missing storm!  Not good coding practice...
      children.should == [rdata, wdgt]
      wdgt.parent.should == self
      wdgt.children.should == [wdgt.vbox]
      wdgt.qtchildren.should == [wdgt.vbox, wdgt.vbox.edt]
      wdgt.vbox.parent.should == wdgt
      wdgt.vbox.children.should == [wdgt.vbox.edt]
      wdgt.vbox.edt.parent.should == wdgt.vbox
      wdgt.vbox.qtparent.should == wdgt
      wdgt.vbox.edt.qtparent.should == wdgt

    } # app
    $shown.should == true
  end # it

  it "should end up in each_sub of application" do
    Reform.app {
      fail_on_instantiation_errors true
      widget {
	name 'wdgt'
	size 320, 240
  	shown { $app.quit }
	vbox {
	  name 'vbx'
	  edit name: 'edt'
	} # vbox
      } # widget
      created do
	$app.should == self
	children.should == [wdgt]
	wdgt.vbx.each_sub.to_a.should == [wdgt.vbx.edt] 
	wdgt.each_child.to_a.should == [wdgt.vbx]
	wdgt.each_sub.to_a.should == [wdgt.vbx, wdgt.vbx.edt]
	each_sub.to_a.should == [wdgt, wdgt.vbx, wdgt.vbx.edt]
      end # created
    } # app
  end #it

  it "with collect_names all items become more readily available" do
    Reform.app {
      fail_on_instantiation_errors true
      collect_names true
      rubydata data: 'Hallo World', name: 'rdata'
      widget {
	name 'wdgt'
	size 320, 240
	title 'Top-level widget'
  	shown { $app.quit }
	vbox {
	  name 'vbx'
	  edit connector: :self, name: 'edt'
	} # vbox
      } # widget
      created do
	$app.should == self
	# this causes a method_missing storm!  Not good coding practice...
	children.should == [rdata, wdgt]
	# note that 'collect_names' uses each_sub, so that must work first.
	each_sub.to_a.should == [rdata, wdgt, wdgt.vbx, wdgt.vbx.edt]
	vbx.each_sub.to_a.should == [edt]
	#tag "wdgt.each_sub = #{wdgt.each_sub.to_a.inspect}"
	wdgt.each_sub.to_a.should == [vbx, edt]
	wdgt.parent.should == self
	wdgt.children.should == [vbx]
	wdgt.qtchildren.should == [vbx, edt]
      end
    } # app
  end
end # describe

