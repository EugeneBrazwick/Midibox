
require_relative '../app'

module R::Qt
    require_relative 'widget'

=begin rdoc
 MainWindows hold a central widget (the first and only one added),
 a menubar, a statusbar, up to 4 docks and several toolbars.
=end
    class MainWindow < Widget
    end # class MainWindow
end # module R::Qt

Reform::createInstantiator __FILE__, R::Qt::MainWindow

if __FILE__ == $0
  R::EForm.app {
    whenExiting { $stderr.puts "Exiting cleanly" }
    mainwindow {
    } # mainwindow
  } # app
end

