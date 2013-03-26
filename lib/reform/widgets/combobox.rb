
#  Copyright (c) 2013 Eugene Brazwick

require_relative 'widget'

module R::Qt

  # Actually ComboBox shares a bunch of methods with AbstractListView
  class ComboBox < Widget
    private # methods of ComboBox

      # rubify Qt signal:
      signal 'currentIndexChanged(int)'

    public # methods of ComboBox

      # override
      def setup hash = nil, &initblock
	super
	#tag "#{self}::setup, connector = #{connector}"
	if connector
	  currentIndexChanged do |idx|
	    if idx < 0
	      data = nil
	    else
	      if @key 
		if @key == :self
		  data = @model.model_index2key idx
		else
		  # FUZZY CODE. 'key' is supposed to be applied to global data
		  # but clearly I apply it to local data here. So this is FAILCODE FIXME
		  data = Model.model_apply_getter @model.model_data(idx), @key
		end
	      else
		data = @model.model_data idx
	      end
	    end
	    #tag "currentIndexChanged to #{idx}, pushing model_data = #{data}"
	    push_data data
          end
	end
      end # setup

      alias want_data want_data_par
      alias push_data push_data_par
 
      attr_dynamic Fixnum, :currentIndex 

      #override
      def apply_model data
	if @key
	  keyval = Model::model_apply_getter data, @key
	  currentIndex @model.model_key2index(keyval)
	else
	  currentIndex @model.model_data2index(data)
	end
      end

      def key con 
	@key = con 
      end

      def display con = nil
	if con
	  @display = con
	else
	  @display || :self
	end
      end

      def decoration con = nil
	if con
	  @decoration = con
	else
	  @decoration
	end
      end
  end

  Reform.createInstantiator __FILE__, ComboBox

end # module R::Qt
