
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'form'

=begin rdoc
a QDialog wrapper
=end
  class Dialog < ReForm
  end # class Dialog

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Dialog, Dialog, form: true

end # module Reform
