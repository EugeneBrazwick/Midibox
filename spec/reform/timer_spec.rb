

require_relative '../../lib/reform/app'
require_relative '../../lib/reform/models/timer'

include R

describe 'Qt::Timer' do
  it 'should have a nice oneShot feature' do
    $quit_called = false
    Reform.app {  # we use widget, so core_app doesn't do it.  But Timer is in core actually...
      # IMPORTANT:	must have an application + event loop.
      # Otherwise Qt says: QTimer can only be used with threads started with QThread
      widget shown: -> { Qt::Timer.oneShot(1000) { $quit_called = true; $app.quit } }
    }
    $quit_called.should == true
  end
end
