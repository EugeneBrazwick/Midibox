#!/usr/bin/ruby

# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

Reform::app {
  mainwindow {

    title tr('Image Viewer')
    sizehint 500, 400 # should work the same as calling resize from the constructor (?)

#     image_model name: :image

    # this is ugly man!
    def updateActions
      checked = fitToWindowAct.checked?
      zoomInAct.enabled = !checked
      zoomOutAct.enabled = !checked
      normalSizeAct.enabled = !checked
    end

    # UGLY
    def self.adjustScrollBar scrollBar, factor
      # FIXME. pageStep appears to be 10, while the imageviewer_a.rb example has 500!
      # But the code is the very same... ????
      v = (factor * scrollBar.value + ((factor - 1.0) * scrollBar.pageStep / 2.0)).to_i
#       tag "v=#{v}, factor=#{factor}, oldvalue = #{scrollBar.value}, pageStep=#{scrollBar.pageStep}"
      scrollBar.value = v
#       tag "scrollBar.value now is #{scrollBar.value}"
    end

    # UGLY
    def scaleImage factor
      @scaleFactor *= factor
#       tag "scaleImage(#{factor}), scaleFactor := #@scaleFactor"
      size = imageLabel.pixmap.size
#       tag "size=#{size.inspect}, resize #{@scaleFactor * size.width}. #{@scaleFactor * size.height}"
      imageLabel.resize @scaleFactor * size.width, @scaleFactor * size.height
      adjustScrollBar scrollArea.horizontalScrollBar, factor
      adjustScrollBar scrollArea.verticalScrollBar, factor
      zoomInAct.enabled = @scaleFactor < 3.0 # UGLY
      zoomOutAct.enabled = @scaleFactor > 0.333 # UGLY
    end

    # a single widget in a main window will become the central widget automatically
    scrollarea {
      # FIXME: scrollbars never show up.... BUG
      name :scrollArea
      # using symbols here to avoid a qt dependency:
      backgroundRole :dark
      # scollareas can only contain one child, so this is it:
      label {
        name :imageLabel
        backgroundRole :base
        sizePolicy :ignored
        scaledContents true
      }
    }
    menuBar { # not a constructor but a reference
      menu { #   fileMenu = menuBar()->addMenu(tr("&File"));
        title tr('&File')
        action { # openAct
          text tr('&Open...')
          shortcut 'Ctrl+O'
          whenTriggered do
            fileName = Qt::FileDialog::getOpenFileName(@qtc, tr('Open File'), Qt::Dir::currentPath())
            unless fileName.empty?
              image = Qt::Image.new fileName
              if image.null?
                Qt::MessageBox::information(@qtc, tr('Image Viewer'), tr("Cannot load %1.").arg(fileName))
                return
              end
              imageLabel.pixmap = Qt::Pixmap::fromImage(image)
              @scaleFactor = 1.0
              printAct.enabled = true
              fitToWindowAct.enabled = true
              updateActions
              imageLabel.adjustSize unless fitToWindowAct.checked?
            end
          end
        }
        action { # printAct
          title tr('&Print...')
          name :printAct
          shortcut 'Ctrl+P'
          disabled
          whenTriggered do
            @printer ||= Qt::Printer.new # better late than a SEGV
            if Qt::PrintDialog.new(@printer, @qtc).exec
              # segv if printer is nil here!
              painter = Qt::Painter.new @printer
              begin
                rect = painter.viewport
                pixmap = imageLabel.pixmap
                size = pixmap.size
                size.scale rect.size, Qt::KeepAspectRatio
                painter.setViewport(rect.x, rect.y, size.width, size.height)
                painter.window = pixmap.rect
                painter.drawPixmap 0, 0, pixmap
              ensure
                painter.end
              end
            end
          end
        }
        separator
        action { # exitAct
          title tr('E&xit')
          shortcut 'Ctrl+Q'
          whenTriggered { @qtc.close }
        }
      }
      menu {
        title tr('&View')
        action {
          text tr('Zoom &In (25%)')
          name :zoomInAct
          shortcut 'Ctrl+='  # Ctrl++ does NOT work properly!
          disabled # UGLY
          whenTriggered { scaleImage 1.25 }
        }
        action {
          text tr('Zoom &Out (25%)')
          name :zoomOutAct
          shortcut 'Ctrl+-'
          disabled # UGLY
          whenTriggered { scaleImage 0.8 }
        }
        action {
          name :normalSizeAct
          text tr('&Normal Size')
          shortcut 'Ctrl+S'
          disabled # UGLY
          whenTriggered { imageLabel.adjustSize; @scaleFactor = 1.0 } # UGLY and wrong, sinze zoomin/out is not enabled
        }
        separator
        action {
          name :fitToWindowAct
          text tr('&Fit to Window')
          shortcut 'Ctrl+F'
          disabled
          checkable true
          whenTriggered do
            fit = fitToWindowAct.checked?
            scrollArea.widgetResizable = fit
            normalSizeAct.whenTriggered unless fit
            updateActions # UGLY
          end
        }
      }
      menu {
        title tr('&Help')
        action {
          title tr('&About')
          whenTriggered do
            Qt::MessageBox::about(@qtc, tr("About Image Viewer"),
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
        }
        action {
          title tr('About &Qt')
          whenTriggered { $qApp.aboutQt }
        }
      }
    }
  }
}
