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

require 'reform/app'
require 'reform/states/state'
require 'reform/graphicsitem'

class QStateSwitchEvent < Qt::Event
  private
    StateSwitchType = Qt::Event::User + 256

    def initialize rand = nil
      super(StateSwitchType)
#       tag "new QStateSwitchEvent"
      @rand = rand
    end

   public

     attr :rand
end

class QStateSwitchTransition < Qt::AbstractTransition
  private
    def initialize rand
      super()
#       tag "QStateSwitchTransition.new"
      @rand = rand
    end

  protected

    # reimplementation of abstract virtual method. Return true if the transition is triggered by the event
    def eventTest event
      (event.type == QStateSwitchEvent::StateSwitchType && event.rand == @rand).tap{|b|tag "eventTest->#{b}"}
    end

      # reimplementation of abstract virtual method
    def onTransition(*)
      tag "onTransition #@rand, source = #{sourceState.objectName}, target = #{targetState.objectName}"
    end

end

class QStateSwitcher < Reform::QState
  private
    def initialize machine
      super
      @stateCount = @lastIndex = 0
#       tag "New QStateSwitcher"
    end

  public
    def onEntry(*)
      tag "#{self}::onEntry"
      while (n = rand(@stateCount) + 1) == @lastIndex
      end
      @lastIndex = n;
      machine.postEvent(QStateSwitchEvent.new(n))
    end

    def onExit(*)
      tag "#{self}::onExit"
    end

    def addState qstate, animation
#       tag "#{self}:'#{objectName}', addState #{qstate}/#{qstate.objectName}, create transition to it with animation"
      trans = QStateSwitchTransition.new(@stateCount += 1)
      trans.targetState = qstate
      addTransition trans
      trans.addAnimation animation
    end

end

module Reform

  class StateSwitcher < AbstractState
    private
      def animation id
        @animation = containing_form[id]
      end

      def states *names
#         tag "Setting states #{names.inspect}"
#         first = true
        names.each do |id|
          # this adds the state to our parents qtc.
#           s = QState.new(parent.qtc)
#           s.objectName = id.to_s
#           tag "locating state '#{id}'"
          @qtc.addState(containing_form[id].qtc, @animation.qtc)
#           if first
#             tag "Setting #{parent.qtc}.initialState to #{s}"
#             parent.qtc.initialState = s
#           end
#           first = false
        end
      end
  end

  registerKlass AbstractState, :switcherstate, QStateSwitcher, StateSwitcher
end

Reform::app {
  form {
    timer {
      autostart false
      name :timer
      interval 1250.ms
      singleShot true
      whenTimeout { tag "timeout"; group.transformTo :switcherState }
    }
    canvas { # window
  #   scene {
      parallelanimation {
        autostart false
        name :animation
        sequentialanimation {
          name :anim_button3
          pause 100.ms
        }
        sequentialanimation {
          name :anim_button2
          pause 150.ms
        }
        sequentialanimation {
          name :anim_button1
          pause 200.ms
        }
        # there is a forth one, but it has no delay. So it is added to :animation immediately
      }
        # SEE:     http://doc.qt.nokia.com/4.6/images/move-blocks-chart.png  !!!
      statemachine {# machine
        state {
          name :group
  #      QState *group = new QState();
  #      group->setObjectName("group");
          states :state1, :state2, :state3, :state4, :state5, :state6, :state7
          whenEntered { tag "entered 'group'"; timer.start }  # QObject::connect(group, SIGNAL(entered()), &timer, SLOT(start()));
  #         group->setInitialState(state1);
        }
        #the crux is that switcherstate is OUTSIDE group. While the states 1 to 7 are within the group!
        switcherstate {
          name :switcherState
          animation :animation
          states :state1, :state2, :state3, :state4, :state5, :state6, :state7
        }
  #      StateSwitcher *stateSwitcher = new StateSwitcher(&machine);
      }
      area 0, 0, 300, 300
      backgroundBrush :black
      rect { #button1 =
        geometry {
          animation {
            states state1: [100, 0, 50, 50], state2: [250, 100, 50, 50],
                  state3: [150, 250, 50, 50], state4: [0, 150, 50, 50],
                  state5: [100, 100, 50, 50], state6: [50, 50, 50, 50],
                  state7: [0, 0, 50, 50]
            duration 1000.ms
            easing Qt::EasingCurve::OutElastic
            appendTo :anim_button1
          }
        }
      }
      rect { # 2
        zValue 1
        geometry {
          animation {
            states state1: [150, 0, 50, 50], state2: [250, 150, 50, 50],
                  state3: [100, 250, 50, 50], state4: [0, 100, 50, 50],
                  state5: [150, 100, 50, 50], state6: [200, 50, 50, 50],
                  state7: [250, 0, 50, 50]
            duration 1000.ms
            easing Qt::EasingCurve::OutElastic
            appendTo :anim_button2
          }
        }
      }
      rect { # 3
        zValue 2
        geometry {
          animation {
            states state1: [200, 0, 50, 50], state2: [250, 200, 50, 50],
                  state3: [50, 250, 50, 50], state4: [0, 50, 50, 50],
                  state5: [100, 150, 50, 50], state6: [50, 200, 50, 50],
                  state7: [0, 250, 50, 50]
            duration 1000.ms
            easing Qt::EasingCurve::OutElastic
            appendTo :anim_button3
          }
        }
      }
      rect { # 4
        zValue 3
        geometry {
          animation {
            states state1: [250, 0, 50, 50], state2: [250, 250, 50, 50],
                  state3: [0, 250, 50, 50], state4: [0, 0, 50, 50],
                  state5: [150, 150, 50, 50], state6: [200, 200, 50, 50],
                  state7: [250, 250, 50, 50]
            duration 1000.ms
            easing Qt::EasingCurve::OutElastic
            appendTo :animation
          }
        }
      }
  #     frameStyle = 0 Qt::Frame::NoFrame but is the default
      alignment :topleft # (Qt::AlignLeft | Qt::AlignTop);
  # #     horizontalScrollBarPolicy Qt::ScrollBarAlwaysOff
  #     verticalScrollBarPolicy Qt::ScrollBarAlwaysOff
      scrollBarPolicy Qt::ScrollBarAlwaysOff
  #     QStateMachine machine;
  #     QTimer timer;
      sizeHint 300
      srand
    } # canvas
  } # form
}

 #include "main.moc"
# Copyright © 2010 Nokia Corporation and/or its subsidiary(-ies)  Trademarks
# Qt 4.6.2
