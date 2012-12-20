
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../layout'

  # forward!
  class Spacer < Widget
  end

=begin
MAJOR HEADACHE CODE

Note that we always do this:
    instantiate qtctrl assigning it to qparentwidget
    instantiate control
    add control to parent, using parent.addControl
    execute setupblock for control
    call postSetup on control

The original design used this syntax:
  gridlayout {
      edit {}
      ...
      goto 4,4
      edit {}...
      span 1, 6
      edit {} ...
}
However, that is not declarative...

It must be
gridlayout {
  edit { span 1,6 }
  edit { layoutpos 0, 1 }
=end
  class GridLayout < Layout

      class RowRef
        private
          def initialize gl, idx
            @qgl, @idx = gl.qtc, idx
          end

          def stretch val = 1
            @qgl.setRowStretch @idx, val
          end

          def minimumHeight val
            @qgl.setRowMinimumHeight @idx, val
          end
      end # class RowRef

      class ColRef
        private
          def initialize gl, idx
            @qgl, @idx = gl.qtc, idx
          end

          def stretch val = 1
            @qgl.setColumnStretch @idx, val
          end

          def minimumWidth val
            @qgl.setColumnMinimumWidth @idx, val
          end
      end # class ColRef

    private # methods of GridLayout

      def initialize parent, qtc
  #       tag "#{self}::new(parent=#{parent}, qtc=#{qtc})"
        super
  #       tag "#{self.class}.new, qtc=#{qtc}" # ???? caller=#{caller.join("\n")}"
  #       @fill = [] # array of rows where each row is a bool array
        # an item in a grid can set col, row and colspan and rowspan
        @columnCount = nil
        @align_labels = :narrow # I'm not sure about this default...
  #       @collection = []
  #       tag "initialized 'collection'"
      end

      # :narrow or :wide
      def align_labels val
        @align_labels = val
      end

      def row(index, &block)
  #       return RowRowRef.new(self) if index.nil?
        RowRef.new(self, index).instance_eval(&block)
      end

      def col(index, &block)
  #       return ColColRef.new(self) if index.nil?
        ColRef.new(self, index).instance_eval(&block)
      end

      def rowStretch ar
        case ar
        when Integer then @qtc.setRowStretch(ar, 1)
        when Hash then ar.each { |k, v| @qtc.setRowStretch(k, v) }
        else ar.each_with_index { |v, i| @qtc.setRowStretch(i, v) }
        end
      end

      def columnStretch ar
        case ar
        when Integer then @qtc.setColumnStretch(ar, 1)
        when Hash then ar.each { |k, v| @qtc.setColumnStretch(k, v) }
        else ar.each_with_index { |v, i| @qtc.setColumnStretch(i, v) }
        end
      end

      def setRowMinimumHeight row, h
        @qtc.setRowMinimumHeight row, h
      end

      def setColumnMinimumWidth row, h
        @qtc.setColumnMinimumWidth row, h
      end

    public  # methods of GridLayout

      def columnCount value = nil
        if value.nil?
  #         tag "columnCount, @columnCount=#@columnCount, qtc.columnCount=#{@qtc.columnCount}, ||=#{@columnCount || @qtc.columnCount}"
          return @columnCount || @qtc.columnCount
        end
        @columnCount = value
      end

      alias :columncount :columnCount
      alias :colcount :columnCount
      alias :columns :columnCount

    private :columns, :colcount, :columncount

      # override
      def postSetup
  #       tag "#{self}::postSetup, @colcount=#@columnCount, @qtc.colcount=#{@qtc.columnCount}"
        curcol, currow = 0, 0
        children.each do |control|
          c, r = control.layoutpos
          no_constraint = c.nil?
          c, r = curcol, currow if no_constraint
          spanc, spanr = control.span
          spanc, spanr = 1, 1 if spanc.nil?
          colCount = columnCount
  #         tag "colCount = #{colCount.inspect}"
          spanc = [1, colCount - c].max if spanc == :all_remaining
  #         tag "qtc.addWidget(#{control}, r:#{r}, c:#{c}, #{spanr}, #{spanc}), layout?->#{control.layout?}"
          if Layout === control
            @qtc.addLayout(control.qtc, r, c, spanr, spanc)
          else
            extra_span = false
            # add a label after it or in front of it, if 'labeltext' was set
            label = nil
            if control.respond_to?(:labeltext) && (labeltext = control.labeltext) # may be a string, may have been converted to a Label reference
  #           tag "#{control}.labeltext = #{label.inspect}"
              label = if labeltext.respond_to?(:qtc) then labeltext.qtc else Qt::Label.new(labeltext) end
              label.buddy = control.qtc
              # if no constraints were set, and if we have 1 column room available, shift 1
              if no_constraint && c < colCount - 1
                @qtc.addWidget(label, r, c, @align_labels == :narrow ?  Qt::AlignRight : Qt::AlignLeft)
                c += 1
              else
                extra_span = c == 0
                @qtc.addWidget(label, r, extra_span ? spanc : c - 1,
                              extra_span == (@align_labels == :narrow) ? Qt::AlignLeft : Qt::AlignRight)
              end
            end
            if Spacer === control
  #             tag "adding spacer #{control.inspect} to the grid hsp=#{control.hor_spacing}, vsp=#{control.ver_spacing}"
              val = control.hor_spacing and @qtc.setColumnMinimumWidth(c, val) #.tap{|x| tag "SET CMW to #{val}" }
              val = control.ver_spacing and @qtc.setRowMinimumHeight(r, val)
              val = control.hor_stretch and @qtc.setColumnStretch(c, val)
              val = control.ver_stretch and @qtc.setRowStretch(r, val)
            else
              if alignment = control.layout_alignment
    #           tag "applying alignment: #{alignment}, ignoring span"
                @qtc.addWidget(control.qtc, r, c, alignment)
              else
    #             tag "addWidget(#{control.qtc}, r=#{r}, c=#{c}, spanr=#{spanr}, spanc=#{spanc})"
                @qtc.addWidget(control.qtc, r, c, spanr, spanc)
              end
              # still, a widget can have 'stretch' set.
              if stretch = control.stretch
                stretch = [stretch, stretch] unless Array === stretch
                stretch[0] and @qtc.setColumnStretch(c, stretch[0])
                stretch[1] and @qtc.setRowStretch(r, stretch[1])
              end
            end
            spanc += 1 if extra_span
          end
          # we just added at column c, so colCount should be [colCount, c + 1].max
          colCount = c + 1 if colCount <= c
          currow, curcol = r, c + spanc
          curcol, currow = 0, currow + 1 if curcol >= colCount
        end
        # a bit of a hack, but probably what you want:
        if children.length == 1
          child = children[0]
          if Widget === child && child.layout_alignment == Qt::AlignCenter
            sizeHint = child.qtc.sizeHint
            @qtc.setRowMinimumHeight(0, sizeHint.height)
            @qtc.setColumnMinimumWidth(0, sizeHint.width)
          end
        end
      end

  end # class GridLayout

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GridLayout, GridLayout

end # Reform