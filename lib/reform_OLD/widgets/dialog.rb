
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'form'

=begin rdoc
a QDialog wrapper
=end
  class Dialog < ReForm
  end # class Dialog

  class QDialog < Qt::Dialog
    include QFormHackContext
  end

  createInstantiator File.basename(__FILE__, '.rb'), QDialog, Dialog, form: true

end # module Reform
