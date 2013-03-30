
#  Copyright (c) 2013 Eugene Brazwick

require_relative 'widget'

module R::Qt
  class LineEdit < Widget 

    private #methods of LineEdit

      signal 'editingFinished()'

    protected #methods of LineEdit

    public #methods of LineEdit

      attr_dynamic String, :text
      attr_dynamic FalseClass, :readOnly
      attr_dynamic Fixnum, :maxLength
      attr_dynamic Array, :alignment   # array of symbolic flags

      alias readOnly? readOnly
      alias readonly? readOnly
      alias readonly readOnly
      alias readonly= readOnly=

      # override
      # Typically one can say  { edit text: { connector: :self } }
      # Which should work like { edit connector: :self }
      def connect_attribute methodname, dynattr
	if methodname == :text
	  editingFinished do
	    unless zombified?
	      # for some reason this event sometimes arrives when the app is being deleted
	      #tag "#{self}::editingFinished(), sender = dynattr #{dynattr}"
	      dynattr.push_data(@mem_text = text) unless @mem_text == text 
	    end
	  end
	else
	  super
	end
      end

      # override
      def setup hash = nil, &initblock
	super # !!!!!
	@mem_text = text
	if connector
	  editingFinished do
	    unless zombified?
	      # for some reason this event sometimes arrives when the app is being deleted
	      #tag "#{self}::editingFinished()"
	      push_data(@mem_text = text) unless @mem_text == text 
	    end
	  end
	end
      end

      # override
      def apply_model data
	#tag "apply_model #{data.inspect}"
	apply_dynamic_setter :text, data
      end
  end

  # req. for a plugin:
  Reform.createInstantiator __FILE__, LineEdit
end

if __FILE__ == $0
  require 'reform/app'
  Reform.app {
    widget {
      edit {
	text 'Hallo World!'
      }
    }
  }
end

