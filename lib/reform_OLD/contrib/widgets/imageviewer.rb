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

=begin KNOWN BUG

  Symptomatic for this kind of programming!!

  actions should be independent of each other.
  We see: enable/disable here and there, so the condition for the state is never made clear

  This is bad!

  Zoom in until zoom-in becomes disabled.
  Then chose: 'normal size'.  But zoom-in is still disabled....

  To fix: use 'enabler' a callback that sets the state based on the model.
  There is a 1 on 1 relationship between the action and the model.
  Only 1 method sets the state of some action.
  It cannot possibly fail!
=end

require 'reform/widgets/mainwindow'

module Reform

  class QImageViewer < Qt::MainWindow
    private
    def initialize
      super
      @imageLabel = Qt::Label.new
      @imageLabel.backgroundRole = Qt::Palette::Base
      @imageLabel.setSizePolicy(Qt::SizePolicy::Ignored, Qt::SizePolicy::Ignored);
      @imageLabel.scaledContents = true;

      @scrollArea = Qt::ScrollArea.new
      @scrollArea.backgroundRole = Qt::Palette::Dark
      # the next two lines can be swapped. Behaves the same (OK).
      self.centralWidget = @scrollArea
      @scrollArea.widget = @imageLabel
      @printer = Qt::Printer.new
      createActions
      createMenus

      self.windowTitle = tr("Image Viewer")
#       resize 500, 400
    end

    def createActions
      @openAct = Qt::Action.new(tr("&Open..."), self);
      @openAct.shortcut = tr("Ctrl+O")
      connect(@openAct, SIGNAL('triggered()'), self, SLOT('open()'));

      @printAct = Qt::Action.new(tr("&Print..."), self);
      @printAct.shortcut = tr("Ctrl+P")
      @printAct.enabled = false
      connect(@printAct, SIGNAL('triggered()'), self, SLOT('print()'));

      @exitAct = Qt::Action.new(tr("E&xit"), self);
      @exitAct.shortcut = tr("Ctrl+Q")
      connect(@exitAct, SIGNAL('triggered()'), self, SLOT('close()'));

      @zoomInAct = Qt::Action.new(tr("Zoom &In (25%)"), self);
      @zoomInAct.shortcut = tr("Ctrl+=")
      @zoomInAct.setEnabled(false);
      connect(@zoomInAct, SIGNAL('triggered()'), self, SLOT('zoomIn()'));

      @zoomOutAct = Qt::Action.new(tr("Zoom &Out (25%)"), self);
      @zoomOutAct.setShortcut(tr("Ctrl+-"));
      @zoomOutAct.setEnabled(false);
      connect(@zoomOutAct, SIGNAL('triggered()'), self, SLOT('zoomOut()'));

      @normalSizeAct = Qt::Action.new(tr("&Normal Size"), self);
      @normalSizeAct.setShortcut(tr("Ctrl+S"));
      @normalSizeAct.setEnabled(false);
      connect(@normalSizeAct, SIGNAL('triggered()'), self, SLOT('normalSize()'));

      @fitToWindowAct = Qt::Action.new(tr("&Fit to Window"), self);
      @fitToWindowAct.setEnabled(false);
      @fitToWindowAct.setCheckable(true);
      @fitToWindowAct.setShortcut(tr("Ctrl+F"));
      connect(@fitToWindowAct, SIGNAL('triggered()'), self, SLOT('fitToWindow()'));

      @aboutAct = Qt::Action.new(tr("&About"), self);
      connect(@aboutAct, SIGNAL('triggered()'), self, SLOT('about()'));

      @aboutQtAct = Qt::Action.new(tr("About &Qt"), self);
      connect(@aboutQtAct, SIGNAL('triggered()'), $qApp, SLOT('aboutQt()'));
  end

  def createMenus
      fileMenu = Qt::Menu.new(tr("&File"), self);
      fileMenu.addAction(@openAct);
      fileMenu.addAction(@printAct);
      fileMenu.addSeparator();
      fileMenu.addAction(@exitAct);

      viewMenu = Qt::Menu.new(tr("&View"), self);
      viewMenu.addAction(@zoomInAct);
      viewMenu.addAction(@zoomOutAct);
      viewMenu.addAction(@normalSizeAct);
      viewMenu.addSeparator();
      viewMenu.addAction(@fitToWindowAct);

      helpMenu = Qt::Menu.new(tr("&Help"), self);
      helpMenu.addAction(@aboutAct);
      helpMenu.addAction(@aboutQtAct);

      menuBar.addMenu(fileMenu);
      menuBar.addMenu(viewMenu);
      menuBar.addMenu(helpMenu);
    end

    def updateActions()
      @zoomInAct.setEnabled(!@fitToWindowAct.isChecked());
      @zoomOutAct.setEnabled(!@fitToWindowAct.isChecked());
      @normalSizeAct.setEnabled(!@fitToWindowAct.isChecked());
    end

    def adjustScrollBar(scrollBar, factor)
      v = (factor * scrollBar.value() + ((factor - 1) * scrollBar.pageStep()/2)).to_i
      tag "v=#{v}, factor=#{factor}, oldvalue = #{scrollBar.value}, pageStep=#{scrollBar.pageStep}"
      scrollBar.setValue(v)
      tag "scrollBar.value now is #{scrollBar.value}"
    end

    def scaleImage factor
      @scaleFactor *= factor;
      size = @imageLabel.pixmap.size
      @imageLabel.resize(@scaleFactor * size.width, @scaleFactor * size.height);

      adjustScrollBar(@scrollArea.horizontalScrollBar(), factor);
      adjustScrollBar(@scrollArea.verticalScrollBar(), factor);

      @zoomInAct.setEnabled(@scaleFactor < 3.0);
      @zoomOutAct.setEnabled(@scaleFactor > 0.333);
    end

    public

    def sizeHint
      Qt::Size.new(500, 400)
    end

    # slot
    def open
      fileName = Qt::FileDialog::getOpenFileName(self,
                                      tr("Open File"), Qt::Dir::currentPath());
      if (!fileName.empty?)
        image = Qt::Image.new(fileName);
        if image.null?
          Qt::MessageBox::information(self, tr("Image Viewer"),
                                        tr("Cannot load %1.").arg(fileName));
          return;
        end
        @imageLabel.setPixmap(Qt::Pixmap::fromImage(image));
        @scaleFactor = 1.0;

        @printAct.setEnabled(true);
        @fitToWindowAct.setEnabled(true);
        updateActions();

        @imageLabel.adjustSize if !@fitToWindowAct.isChecked()
      end
    end

    # slot
    def print()
      dialog = Qt::PrintDialog.new(@printer, self);
      if (dialog.exec())
          painter = Qt::Painter.new(@printer);
          rect = painter.viewport();
          size = @imageLabel.pixmap().size();
          size.scale(rect.size(), Qt::KeepAspectRatio);
          painter.setViewport(rect.x(), rect.y(), size.width(), size.height());
          painter.setWindow(@imageLabel.pixmap().rect());
          painter.drawPixmap(0, 0, @imageLabel.pixmap());
          painter.end
      end
    end

    # slot
    def zoomIn()
      scaleImage(1.25);
    end

    # slot
    def zoomOut()
      scaleImage(0.8);
    end

    # slot
    def normalSize()
      @imageLabel.adjustSize();
      @scaleFactor = 1.0;
    end

    # slot
    def fitToWindow()
      fitToWindow = @fitToWindowAct.isChecked();
      @scrollArea.setWidgetResizable(fitToWindow);
      normalSize unless fitToWindow
      updateActions();
    end

    # slot
    def about()
      Qt::MessageBox::about(self, tr("About Image Viewer"),
              tr("<p>The <b>Image Viewer</b> example shows how to combine QLabel " +
                  "and QScrollArea to display an image. QLabel is typically used " +
                  "for displaying a text, but it can also display an image. " +
                  "QScrollArea provides a scrolling view around another widget. " +
                  "If the child widget exceeds the size of the frame, QScrollArea " +
                  "automatically provides scroll bars. </p><p>The example " +
                  "demonstrates how QLabel's ability to scale its contents " +
                  "(QLabel::scaledContents), and QScrollArea's ability to " +
                  "automatically resize its contents " +
                  "(QScrollArea::widgetResizable), can be used to implement " +
                  "zooming and scaling features. </p><p>In addition the example " +
                  "shows how to use QPainter to print an image.</p>"));
    end

    slots 'open()', 'print()', 'zoomIn()', 'zoomOut()', 'normalSize()', 'fitToWindow()', 'about()'
  end

  createInstantiator File.basename(__FILE__, '.rb'), QImageViewer, MainWindow, form: true
end

