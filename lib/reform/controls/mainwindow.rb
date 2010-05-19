
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'form'

=begin rdoc
 a ReForm is a basic form. It inherits Frame
 but is meant as a complete window.
=end
  MainWindow = ReForm

  createInstantiator File.basename(__FILE__, '.rb'), Qt::MainWindow, MainWindow, form: true

end # Reform
