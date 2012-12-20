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
    title tr('SVG Viewer')
    @currentPath = ''

    def openFile path = ''
#       tag "openFile(#{path})"
      fileName = if path.empty? then Qt::FileDialog.getOpenFileName(@qtc, tr('Open SVG File'),
                                                                    @currentPath,
                                                                    'SVG files (*.svg *.svgz *.svg.gz)')
                 else path
      end
      return if fileName.empty?
      file = Qt::File.new(fileName)
      unless file.exists
        Qt::MessageBox::critical(@qtc, tr('Open SVG File'),
                                 tr("Could not open file '%s'.") % [fileName])
  # FIXME: this must be done through the model (YES!) There is no shape....
        outlineAction.disable
        backgroundAction.disable
        return
      end
      view.openFile file # ugly
      unless fileName[0, 2] == ':/'
        @currentPath = fileName
        title tr('%s - SVGViewer') % [@currentPath]
      end
      outlineAction.enabled = true
      backgroundAction.enabled = true
      tag "view.qtc.sizeHint=#{view.qtc.sizeHint.inspect}"
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
      # FIXME:  ARGHH-code:
      @renderer = :native # we have :native, :openGL and :image
      @svgItem = @backgroundItem = @outlineItem = nil
      @image = Qt::Image.new

      def drawBackground p
        p.save do
          p.resetTransform
          p.drawTilePixmap(viewport.rect, backgroundBrush.texture)
        end
      end

      # FIXME:  more ARGHH-code:
      def openFile qfile
        return unless qfile.exists
        s = scene
        drawBackground = @backgroundItem && @backgroundItem.visible?
        drawOutline = @outlineItem && @outlineItem.visible?
        s.clear
        resetTransform
        @svgItem = Qt::GraphicsSvgItem.new(qfile.fileName) # ??????? WTF ???
        @svgItem.flags = Qt::GraphicsItem::ItemClipsToShape
        @svgItem.cacheMode = Qt::GraphicsItem::NoCache
        @svgItem.setZValue 0
        @backgroundItem = Qt::GraphicsRectItem.new(@svgItem.boundingRect)
        @backgroundItem.brush = color2brush :white
        @backgroundItem.pen = Qt::Pen.new(Qt::NoPen)  # FIXME: cache this?
        @backgroundItem.visible = drawBackground
        @backgroundItem.setZValue -1
        @outlineItem = Qt::GraphicsRectItem.new(@svgItem.boundingRect)
        # FIXME: need a pen construction to this in a one liner. With proper attribnames
        # Like          pen { color: black, width: 2, style: :dash, cosmetic: true }
        outline = Qt::Pen.new(color2brush(:black), 2, Qt::DashLine)
        outline.cosmetic = true
        @outlineItem.pen = outline
        @outlineItem.brush = Qt::Brush.new(Qt::NoBrush) #  FIXME: cache this
        @outlineItem.visible = drawOutline
        @outlineItem.zValue = 1
        s.addItem(@backgroundItem)
        s.addItem(@svgItem)
        s.addItem(@outlineItem)
        s.sceneRect = @outlineItem.boundingRect.adjusted(-10, -10, 10, 10)
      end

      def viewBackground= onoff
        return unless @backgroundItem
        @backgroundItem.visible = onoff
      end

      def viewOutline= onoff
        return unless @outlineItem
        @outlineItem.visible = onoff
      end

      def renderer= sym
        if (@renderer = sym) == :openGL
          setViewport(Qt::GLWidget.new(Qt::GLFormat.new(Qt::GL::SampleBuffers)))
        else
          setViewport(Qt::Widget.new)
        end
      end

      def highQualityAntiAliasing= onoff
        setRenderHint(Qt::Painter::HighQualityAntialiasing, onoff)
      end

      alias :org_render :render

  # CRAP QT!!  It seems a QGraphicsView must paint on the 'viewport' whatever it is.
   #SO   the caller must already create the proper painter..... The example does not
   #show this since it reverts to the parent call.

      whenPainted do |painter|
#         return false
        tag "whenPainted...."
        if @renderer == :image
          if @image.size != viewport.size
            @image = Qt::Image.new(viewport.size, Qt::Image::Format_ARGB32_Premultiplied)
          end
          tag "creating painter for image"
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
        action {
          label tr('E&xit')
          shortcut :quit
          whenTriggered { $qApp.quit }
        }
      } # fileMenu
      menu { # viewMenu
        title tr('&View')
        action {
          name :backgroundAction
          label tr('&Background')
          disabled
          checkable true
          checked false
          # something with model here???? Done already somewhere else???
          whenToggled { |checked| view.viewBackground = checked }
        }
        action {
          name :outlineAction
          label tr('&Outline')
          disabled
          checked true
          whenToggled { |checked| view.viewOutline = checked }
        }
      } # viewMenu
      menu { # rendererMenu
        title tr('&Renderer')
        actiongroup {
          action {
            label tr('&Native')
            checked true
            whenTriggered { view.renderer = :native }  # FIXME: must be data-driven!
          }
          action {
            label tr('&OpenGL')
            checkable true
            whenTriggered { view.renderer = :openGL }
          }
          action {
            label tr('&Image')
            checkable true
            whenTriggered { view.renderer = :image }
          }
#  UGLY          whenTriggered { |action| setRenderer(action) }
        } # actionGroup
        separator
        action {
          label tr('&High Quality Antialiasing')
          disabled
          checkable true
          checked false
          whenToggled { |checked| setHighQualityAntialiasing(checked) }
        }
      } # rendererMenu
    } # menuBar
    # at the end is better....
    whenShown do
      openFile(ARGV[1] || File.dirname(__FILE__) + "/images/bubbles.svg");
    end
  } # mainwindow
}
