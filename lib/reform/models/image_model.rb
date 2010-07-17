
# Copyright (c) 2010 Eugene Brazwick

require_relative '../model'

module Reform
  # model class representing the current time.
  # It reconnects to the control each second (by default).
  class ImageModel < Qt::Image
    include Model

    def fileName= aFilename
      raise ReformError, tr("Loading image '#{aFilename}' failed") unless load(aFilename)
      dynamicPropertyChanged :fileName
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), nil, ImageModel

end
