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

require 'reform/app'

Reform::app {
  mainwindow {

=begin

what's our data?

we have a 'shape' loaded from disk.
We may move the shape loading stuff to a constructor, as long as we can keep
the original filename as it is to become the window title.

But passing it just to the view is not good enough since the actions in the
mainwindow are tied to the data!
It is however not possible to create an item and then load it from disk later.

It is also interesting to read the actual svg files. Since they look a lot like
this stuff here...

Anyway, let's attempt to get away with using Structure.
=end

    structure name: :data, value: { drawBackground: false, drawOutline: true, title: tr('SVG Viewer'),
                                    renderer: :native, highQualityAntiAliasing: false }

    title connector: :title # this activates the automatic title setting, works for mainwindow or form.
    @currentPath = '' # more used as 'last used'

    def openFile path = nil
#       tag "openFile(#{path})"
      fileName = path || Qt::FileDialog.getOpenFileName(@qtc, tr('Open SVG File'), @currentPath,
                                                        'SVG files (*.svg *.svgz *.svg.gz)') or return
      # getOpenFileName may return '' for some reason....
      return if fileName.empty?
      unless File.exists?(fileName)
        return Qt::MessageBox::critical(@qtc, tr('Open SVG File'),
                                        tr("Could not open file '%s'.") % [fileName])
      end
      d.svgItem = Qt::GraphicsSvgItem.new fileName
      @currentPath = fileName
      d = data
      d.title = tr('%s - SVGViewer') % [fileName]
#       tag "view.qtc.sizeHint=#{view.qtc.sizeHint.inspect}"
      # resize view.qtc.sizeHint + Qt::Size.new(80, 80 + menuBar.height)                FIXME this fails. sizeHint is 0.0??
    end

    sizeHint 640, 480
    canvas {
      name :view
      scene {
      }
      transformationAnchor AnchorUnderMouse # Qt::GraphicsView::AnchorUnderMouse
      dragMode ScrollHandDrag
      viewportUpdateMode FullViewportUpdate
      background brushRecipy {
          tilePixmap = Qt::Pixmap.new(64, 64)
          tilePixmap.fill   #  Qt::white  is the default....
          # UGLY bit follows: because these are two 'rectangle' object instances.
          # brush color2brush(220, 220, 220)   . set parent brush
          # rectangle rect: [0, 0, 32, 32]
          # rectangle rect: [32, 32, 32, 32]
          # Painting on a device should not be different than adding items to a scene
          require 'reform/painter'
          Reform::Painter.new(tilePixmap) do |p|
            color = Qt::Color.new(220, 220, 220)
            p.fillRect(0, 0, 32, 32, color)
            p.fillRect(32, 32, 32, 32, color)
          end
          tilePixmap
        }
      @data = nil               # a copy of the model
      # FIXME:  ARGHH-code:
      @image = Qt::Image.new

      def drawBackground p
        p.save do
          p.resetTransform
          p.drawTilePixmap(viewport.rect, backgroundBrush.texture)
        end
      end

      # FIXME:  more ARGHH-code:
      # This should be whenConnected but it runs in the forms scope.
      # It better move to a higher level
      def updateModel model, options
        @data = model
        case options[:property]
        when :drawBackground
          model.backgroundItem.visible = model.drawBackground? if model.backgroundItem
        when :drawOutline
          model.outlineItem.visible = model.drawOutline? if model.outlineItem
        when :svgItem
          tag "so svgItem has changed"
          # so the others can now use @data
          svgItem = @data.svgItem or return super
          s = scene
          s.clear
          resetTransform
          svgItem.flags = Qt::GraphicsItem::ItemClipsToShape
          svgItem.cacheMode = Qt::GraphicsItem::NoCache
          svgItem.setZValue 0
          boundingRect = svgItem.boundingRect
          bItem = @data.backgroundItem = Qt::GraphicsRectItem.new(boundingRect)
          bItem.brush = color2brush :white
          bItem.pen = Qt::Pen.new(Qt::NoPen)  # FIXME: cache this?
          bItem.visible = @data.drawBackground?
          bItem.setZValue -1
          outlineItem = @data.outlineItem = Qt::GraphicsRectItem.new(boundingRect)
          # FIXME: need a pen construction to this in a one liner. With proper attribnames
          # Like          pen { color: black, width: 2, style: :dash, cosmetic: true }
          outline = Qt::Pen.new(color2brush(:black), 2, Qt::DashLine)
          outline.cosmetic = true
          outlineItem.pen = outline
          outlineItem.brush = Qt::Brush.new(Qt::NoBrush) #  FIXME: cache this
          outlineItem.visible = @data.drawOutline
          outlineItem.zValue = 1
          s.addItem(bItem)
          s.addItem(svgItem)
          s.addItem(outlineItem)
          s.sceneRect = boundingRect.adjusted(-10, -10, 10, 10)
        when :renderer
          tag "set renderer"
          if @data.renderer == :openGL
            setViewport(Qt::GLWidget.new(Qt::GLFormat.new(Qt::GL::SampleBuffers)))
          else
            setViewport(Qt::Widget.new)
          end
        when :highQualityAntiAliasing
          setRenderHint(Qt::Painter::HighQualityAntialiasing, @data.highQualityAntiAliasing?)
        end
        super
      end

      alias :org_render :render

  # CRAP QT!!  It seems a QGraphicsView must paint on the 'viewport' whatever it is.
   #SO   the caller must already create the proper painter..... The example does not
   #show this since it reverts to the parent call.

      whenPainted do |painter|
#         return false
#         tag "whenPainted...."
        if @data.renderer == :image
          if @image.size != viewport.size
            @image = Qt::Image.new(viewport.size, Qt::Image::Format_ARGB32_Premultiplied)
          end
#           tag "creating painter for image"
          Reform::Painter::new(@image) { |pnt| org_render(pnt) }
          p = Qt::Painter.new(viewport)
          p.drawImage(0, 0, @image)
        else
          false
        end
      end
    }
    menuBar {
      menu { # fileMenu
        title tr('&File')
        action {
          label tr('&Open...')
          shortcut tr('Ctrl+O')
          whenTriggered { openFile }
        }
        quiter
      } # fileMenu
      menu { # viewMenu
        title tr('&View')
        action {
          name :backgroundAction
          label tr('&Background')
          enabler :svgItem
          checkable true
          connector :viewBackground
#           disabled
#           checkable true
#           checked false
          # something with model here???? Done already somewhere else???
#           whenToggled { |checked| view.viewBackground = checked }
        }
        action {
          name :outlineAction
          label tr('&Outline')
          enabler :svgItem
          connector :viewOutline
          checkable true
#           disabled
#           checked true
#           whenToggled { |checked| view.viewOutline = checked }
        }
      } # viewMenu
      menu { # rendererMenu
        title tr('&Renderer')
        actiongroup {
          action {
            label tr('&Native')
            value :native
            checkable true
            connector :renderer
          }
          action {
            label tr('&OpenGL')
            value :openGL
            checkable true
            connector :renderer
          }
          action {
            label tr('&Image')
            checkable true
            value :image
            connector :renderer
          }
#  UGLY          whenTriggered { |action| setRenderer(action) }
        } # actionGroup
        separator
        action {
          label tr('&High Quality Antialiasing')
          enabler :svgItem
          checkable true
          connector :highQualityAntiAliasing
        }
      } # rendererMenu
    } # menuBar
    # at the end is better....
    whenShown do
      openFile(ARGV[0] || File.dirname(__FILE__) + "/images/bubbles.svg");
    end
  } # mainwindow
}
