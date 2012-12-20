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

require 'reform/app'  # the only one we need

# path must be relative to the root-reform directory.
Reform::registerControlClassProxy 'circlewidget', 'examples/painting/inc/circlewidget'

Reform::app {
  title tr('Concentric Circles')
  form {
    time_model { updatetime_ms 100 }
    gridlayout {
      # create an instance method, just a helper within the gridlayout.
      def createLabel aText, col, row
        label {
          text aText
          margin 2
          alignment :center
          frameStyle Qt::Frame::Box | Qt::Frame::Sunken
          layoutpos col, row
        }
      end
      createLabel tr('Aliased'), 1, 0
      createLabel tr('Antialiased'), 2, 0
      createLabel tr('Int'), 0, 1
      createLabel tr('Float'), 0, 2
      circlewidget antialiased: false, floatBased: false, layoutpos: [1, 1], connector: :frameNr
      circlewidget antialiased: true, floatBased: false, connector: :frameNr
      circlewidget antialiased: false, floatBased: true, layoutpos: [1, 2],  connector: :frameNr
      circlewidget antialiased: true, floatBased: true,  connector: :frameNr
    }
  }
}
