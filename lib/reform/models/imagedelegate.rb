
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../delegatemodel'

  # class that displays an image within a view, like a table
  # However it is very specifically used for the 'icons' example widget.
  # Since this looks ALOTLIKE Model, it should somehow we fused together.
  class QImageDelegate < Qt::ItemDelegate
=begin
/****************************************************************************
 **
 ** Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 ** All rights reserved.
 ** Contact: Nokia Corporation (qt-info@nokia.com)
 **
 ** This file is part of the examples of the Qt Toolkit.
 **
 ** $QT_BEGIN_LICENSE:LGPL$
 ** Commercial Usage
 ** Licensees holding valid Qt Commercial licenses may use this file in
 ** accordance with the Qt Commercial License Agreement provided with the
 ** Software or, alternatively, in accordance with the terms contained in
 ** a written agreement between you and Nokia.
 **
 ** GNU Lesser General Public License Usage
 ** Alternatively, this file may be used under the terms of the GNU Lesser
 ** General Public License version 2.1 as published by the Free Software
 ** Foundation and appearing in the file LICENSE.LGPL included in the
 ** packaging of this file.  Please review the following information to
 ** ensure the GNU Lesser General Public License version 2.1 requirements
 ** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
 **
 ** In addition, as a special exception, Nokia gives you certain additional
 ** rights.  These rights are described in the Nokia Qt LGPL Exception
 ** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
 **
 ** GNU General Public License Usage
 ** Alternatively, this file may be used under the terms of the GNU
 ** General Public License version 3.0 as published by the Free Software
 ** Foundation and appearing in the file LICENSE.GPL included in the
 ** packaging of this file.  Please review the following information to
 ** ensure the GNU General Public License version 3.0 requirements will be
 ** met: http://www.gnu.org/copyleft/gpl.html.
 **
 ** If you have questions regarding the use of this file, please contact
 ** Nokia at qt-info@nokia.com.
 ** $QT_END_LICENSE$
 **
 ****************************************************************************/
=end

    public
    # override. These are typically two 'models'
    def createEditor parent, option, index
      # this will be the 'editor':
      comboBox = Qt::ComboBox.new(parent)
      case index.column
      when 1
        comboBox.addItem tr("Normal")
        comboBox.addItem tr("Active")
        comboBox.addItem tr("Disabled")
        comboBox.addItem tr("Selected")
      when 2
        comboBox.addItem tr("Off")
        comboBox.addItem tr("On")
      end
      # commitData: This signal must be emitted when the editor widget has completed
      # editing the data, and wants to write it back into the model.
      connect(comboBox, SIGNAL('activated(int)')) { commitData(comboBox) }
    end

    # override. Outside change, reflect by setting currentIndex in combo
    def setEditorData comboBox, index
      return unless comboBox.inherits('QComboBox')
      pos = comboBox.findText(index.model.data(index).toString, Qt::MatchExactly)
      comboBox.currentIndex = pos
    end

    #override. Picked an item in the combo (through commitData slot)
    def setModelData comboBox, model, index
      return unless comboBox.inherits('QComboBox')
      model.setData index, comboBox.currentText
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QImageDelegate, DelegateModel

end