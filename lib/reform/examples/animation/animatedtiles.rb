=begin
 /****************************************************************************
 **
 ** Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 ** All rights reserved.
 ** Contact: Nokia Corporation (qt-info@nokia.com)
 **
 ** This file is part of the QtCore module of the Qt Toolkit.
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

require 'Qt'
require 'reform/graphical'
require 'reform/controls/canvas'

# see otherwise 'sub attack' for a PixmapItem class
# NOTE: I remove Qt::Object so Pixmap may lack important functionality
class Pixmap < Qt::GraphicsPixmapItem
  private
    def initialize pix
      super
      setCacheMode DeviceCoordinateCache
    end

  public

    attr_accessor :pos

end # class Pixmap

class Button < Qt::GraphicsWidget
  include Reform::Graphical
  private
    def initialize pixmap, parent = nil
      if parent
        super(parent)
      else
        super()
      end
      @pix = pixmap
      setAcceptHoverEvents true
      setCacheMode DeviceCoordinateCache
    end

  public
    def boundingRect
      Qt::RectF.new(-65, -65, 130, 130);
    end

    def shape
      path =Qt::PainterPath.new
      path.addEllipse(boundingRect());
      path;
    end

    def paint(painter, option, *)
      down = (option.state & Qt::Style::State_Sunken) != 0
      r = boundingRect();
      grad = Qt::LinearGradient.new(r.topLeft(), r.bottomRight());
      grad.setColorAt(down ? 1 : 0, color((option.state & QStyle::State_MouseOver) != 0 ? :white : :lightGray));
      grad.setColorAt(down ? 0 : 1, color(:darkGray));
      painter.pen = make_pen(:darkGray)
      painter.brush = make_brush(grad);
      painter.drawEllipse(r);
#       grad2 = Qt::LinearGradient.new(r.topLeft(), r.bottomRight()); ??
      grad.setColorAt(down ? 1 : 0, color(:darkGray));
      grad.setColorAt(down ? 0 : 1, color(:lightGray));
      painter.pen = make_pen(:none)
      setPen(Qt::NoPen);
      painter.brush = make_brush(grad);
      down and painter.translate(2, 2);
      painter.drawEllipse(r.adjusted(5, 5, -5, -5));
      painter.drawPixmap(-@pix.width()/2, -@pix.height()/2, @pix);
    end

    signals 'void pressed()'

  protected
     def mousePressEvent(*)
       pressed();
       update();
     end

     def mouseReleaseEvent(*)
       update();
     end
end

require 'reform/controls/canvas'
require 'reform/graphicsitem'

class View < Qt::GraphicsView

  private
#     def initialize scene ) : QGraphicsView(scene) { }

  protected
    def resizeEvent event
      super
      fitInView(sceneRect(), Qt::KeepAspectRatio);
    end

end

Reform::createInstantiator :view, View, Reform::Canvas
Reform::createInstantiator :gbutton, Button
Reform::createInstantiator :pixmap, Pixmap, Reform::GraphicsItem

require 'reform/app'

PixmapPath = File.dirname(__FILE__) + '/images/'

Reform::app {
  view {
    kineticPix = Qt::Pixmap.new(PixmapPath + "kinetic.png");
    title tr("Animated Tiles")
    viewportUpdateMode Qt::GraphicsView::BoundingRectViewportUpdate
    backgroundBrush 'file://' + PixmapPath + 'Time-For-Lunch-2.jpg'
    cacheMode Qt::GraphicsView::CacheBackground
    renderHints Qt::Painter::Antialiasing | Qt::Painter::SmoothPixmapTransform

    scene {
      area -350, -350, 700, 700
      # animates our 64 controls in parallel
      parallelanimationgroup name: :anim
      timer {
        timeout_ms 125
        singleShot true
        targetState :ellipseState, :anim
      }
  #     trans = rootState->addTransition(&timer, SIGNAL(timeout()), ellipseState);
  #     trans->addAnimation(group);
#       @items = []
      stateMachine {
  #       initialState :rootState
#         state {               this is implicit if states is used within stateMachine
#           name :rootState # QState *rootState = new QState;
  #         initial true  # first state automatically is initial
  #         state name: :centeredState # , initial: true
  #         state name: :ellipseState #State = new QState(rootState);
  # #         state name: :figure8State #  QState *figure8State = new QState(rootState);
  # #         state name: :randomState
  #         state name: :tiledState
        states :centeredState, :ellipseState, :figure8State, :randomState, :tiledState
#         }
      }
      (0...64).each do |i|
        pixmap {
          image kineticPix
           #offset is specific for  Qt::GraphicsPixmapItem
          offset -kineticPix.width()/2, -kineticPix.height()/2
          zValue i

          position {
            animation ellipseState: [cos((i / 63.0) * 6.28) * 250, sin((i / 63.0) * 6.28) * 250],
                   #ellipseState->assignProperty(item, "pos",
                    #                      QPointF(cos((i / 63.0) * 6.28) * 250,
                     #                             sin((i / 63.0) * 6.28) * 250));
                      figure8State: [sin((i / 63.0) * 6.28) * 250, sin(((i * 2)/63.0) * 6.28) * 250],
                      randomState: [-250 + rand(500), -250 + rand(500)],
                      tiledState: [((i % 8) - 4) * kineticPix.width() + kineticPix.width() / 2,
                                   ((i / 8) - 4) * kineticPix.height() + kineticPix.height() / 2],
                      centeredState: [0.0, 0.0]
#           propertyanimation {
#             property :pos
#             QPropertyAnimation *anim = new QPropertyAnimation(items[i], "pos");
            duration 750 + i * 25
            easingCurve Qt::EasingCurve::InOutBack
            group :anim # ->addAnimation(anim);
          } # position

#         items << item;  ???
#          scene.addItem(item)
        } # pixmap 0..63
      end
      rect { # buttonParent
        scale 0.75
        pos 200
        zValue 65
        gbutton image: PixmapPath + 'ellipse.png', pos: [-100, -100], name: :ellipseButton,
                targetState: [:ellipseState, :anim]
        gbutton image: PixmapPath + 'figure8.png', pos: [100, -100], name: :figure8Button,
                targetState: [:figure8State, :anim]
#         transition observe: :figure8Button, signal: 'pressed()', target: :figure8State,
#                   animation: :parallelanimationgroup
        gbutton image: PixmapPath + 'random.png', pos: [0, 0], name: :randomButton,
                targetState: [:randomState, :anim]
        gbutton image: PixmapPath + 'tile.png', pos: [-100, 100], name: :tiledButton,
                targetState: [:tiledState, :anim]
        gbutton image: PixmapPath + 'centered.png', pos: [100, 100], name: :centeredButton,
                targetState: [:centeredState, :anim]
      } # rect
    } # scene
  } # view
} # app
=begin

Each item has some property 'pos' in each state.
Like:

=end

#      // States
#           transition {
#             observe :ellipseButton
# #             signal 'pressed()'
#             target :ellipseState   # VAGUE
#             group :parallelanimationgroup
#           }
  #         QAbstractTransition *trans = rootState->addTransition(ellipseButton, SIGNAL(pressed()), ellipseState);
  #      trans->addAnimation(group);

    # This is a bit ugly.  The state already have names and that makes sense.
    # Can we not move this to the observed control?
#           transition observe: :tiledButton, signal: 'pressed()', target: :tiledState,
#                     animation: :parallelanimationgroup
#           transition observe: :centeredButton, signal: 'pressed()', target: :centeredState,
#                     animation: :parallelanimationgroup
#           transition observer: :timer, signal: 'timeout()', target: :ellipseState,
#                     animation: :parallelanimationgroup
#         } # rootState
#       } # stateMachine

  #      QStateMachine states;
  #      states.addState(rootState);
  #      states.setInitialState(rootState);
  #      rootState->setInitialState(centeredState);

    # what's this doing here?
    # what is the relation with the stateMachine?

  #     QTimer timer;
  #     timer.start(125);
  #     timer.setSingleShot(true);
  #     trans = rootState->addTransition(&timer, SIGNAL(timeout()), ellipseState);
  #     trans->addAnimation(group);

  #     states.start();           ! SOmewhere ????
# #     } # scene
#   } # view
 #ifdef QT_KEYPAD_NAVIGATION
#      dQApplication::setNavigationMode(Qt::NavigationModeCursorAuto);
 #endif
#      return app.exec();
# }

#  #include "main.moc"