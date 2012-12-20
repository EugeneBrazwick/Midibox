
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../abstractAction'

  # Note that a separator in a menubar may be ignored by the style. Example: default Lucid style.
  class Separator < AbstractAction
    def addTo parent, hash, &block
#       tag "addSeparator to #{parent}, qtc=#{parent.qtc}"
      parent.qtc.addSeparator
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), nil, Separator

end