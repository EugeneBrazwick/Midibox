=begin
****************************************************************************
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
 ****************************************************************************
=end

# IMPORTANT, widget.rb MUST be loaded, since we use it implicitely in 'createInstantiator'
require_relative '../controls/widget.rb'

module Reform

  class QDigitalClock < Qt::LCDNumber
  private
    def initialize parent = nil
      super(parent || 5)  # for some weird reason super(nil) is not accepted!!
      self.segmentStyle = Filled

      timer = Qt::Timer.new self
      connect timer, SIGNAL('timeout()'), self, SLOT('showTime()')
      timer.start 1000 # ms

      showTime

      self.windowTitle = tr('Digital Clock')
      resize 150, 60
    end

    def showTime
      time = Qt::Time::currentTime
      display time.toString(if time.second % 2 == 0 then 'hh mm' else 'hh:mm' end)
    end

    slots 'showTime()'
  end # class QDigitalClock

  createInstantiator File.basename(__FILE__, '.rb'), QDigitalClock
end # module Reform
