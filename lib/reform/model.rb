
#  Copyright (c) 2013 Eugene Brazwick

require_relative 'control'

module R::Qt
  class Model < Control

      class PropertyChange
      end # class PropertyChange

    private # methods of Model

      def initialize *args
	super
	# listener tree, see add_listener
	@model_listeners = [] 
      end # initialize

      # every node in the controlpath can have a connector set
      def model_init_path controlpath
	#tag "model_init_path(#{controlpath.inspect})"
	v = self
	lastcontrol = nil
	controlpath.each do |control|
	  v &&= Model::model_apply_connector v, control
	  lastcontrol = control
	end
	#tag "lastcontrol=#{lastcontrol}"
	lastcontrol.apply_model(v) if v && lastcontrol
      end # model_init_path

      def model_propagate cidpath, value, sender
	Model::model_propagate_i cidpath, value, sender, self, @model_listeners
      end

      def self.model_apply_connector v, control, cidpath = nil
	model_apply_cid( v, control && control.connector, cidpath)
      end # model_apply_connector

      def self.model_apply_cid v, cid, cidpath
	tag "model_apply_cid on #{v}, cid = #{cid.inspect}"
	case cid
	when NilClass
	  tag "nil"
	  v
	when Proc
	  cid[v]
	when Array
	  tag "Array, apply them in order"
	  cid.inject(v) do |w, nm|
	    w && model_apply_cid(w, nm, cidpath) 
	  end
	else
	  tag "should be symbol, delegate to model_apply_getter"
	  cidpath << cid if cidpath
	  v.model_apply_getter cid
	end # case
      end # model_apply_cid

      # this works. But self inside any method still is the keyword.
      # Using this we don't need to hack the ':self' cid, at least
      # for reading.
      def self
	self
      end

      def self.model_propagate_cid cidpath, control, cid, value, sender, v, subs
	tag "PROPAGATE_CID(#{cidpath.inspect}, #{cid.inspect}, on #{v}, subs = #{subs})"
	case cid
	when NilClass
	when Proc
	  cidpath = nil
	  v = cid[v]
	when Array
	  cid.each do |el|
	    v &&= model_propagate_cid cidpath, control, el, value, sender, v, subs
	  end
	  return v
	else
	  if cidpath
	    return nil unless cidpath[0] == cid
	    cidpath.shift
	  end
	  v = v.model_apply_getter cid
	end
	if subs
	  model_propagate_i cidpath, value, sender, v, subs
	else
	  unless control.equal? sender
	    tag "ARRIVAL at accepting endpoint #{control}, v = #{v}"
	    control.apply_model(v) if v
	  end
	end
	v
      end # model_propagate_cid

    protected # methods of Model

    # cidpath is an array of cids. This shows how ichanged 'value' fits 
    # into this model. A listener must have this cidpath as a prefix, or
    # it must contain a Proc cid.  For this reason cidpath can be nil and
    # we must then broadcast.
    # value is the new value. Do not use. This should describe the change
    # better.
    # sender is the control that instigated the change. We must skip it 
    # when sending a message (but not its children).
    # listeners are the receivers as listenertree. It is always an array. 
    # See model_merge_listener_path.
    # Note we must not change the model, that's already been done.
    # We must inform all controls that connect to cidpath and reattach
    # by calling control.apply_model
      def self.model_propagate_i cidpath, value, sender, v, listeners
	tag "PROPAGATE(#{cidpath.inspect}, #{value}, on #{v}, listeners = #{listeners})"
	listeners.each do |listener|
	  if Array === listener 
	    control, *subs = listener
	  else
	    control, subs = listener, nil
	  end
	  model_propagate_cid cidpath, control, control.connector, value, sender, v, subs
	end # each
      end # model_propagate_i

      # listeners: tree to build.
      # A control can be put in the tree 'as is'. This means it is an endpoint.
      # If a control has children it is stored as an array:  [parent, child1, child2...]
      # controlpath: array of controls
      #   []
      #	  [a]
      #	  [[a, [b, c]]]
      #	  [[a, [b, c]], d]
      #	  [[a, [b, c]], [d, e]]
      #	  [[a, [b, c, f]], [d, e]]
      #	  [[a, [b, c, f]], [d, e], g]
      #   []
      #	  [a]
      #	  [a, g]
      #	  [[a, b], g]
      #	  [[a, [b, [d, e]]], g]
      def self.model_merge_listener_path listeners, controlpath
	control = controlpath[0]
	index = listeners.find_index do |l|
	  l.equal?(control) || Array === l && l[0].equal?(control)
	end
	if index
	  return if controlpath.length == 1  
	  listener = listeners[index]
	  if listener.equal?(control)
	    listener = listeners[index] = [listener]
	    # and otherwise it is already an array
	  end
	else
	  if controlpath.length == 1  
	    listeners << control
	    return
	  end
	  index = listeners.length
	  listeners << (listener = [control])
	end
	model_merge_listener_path listener, controlpath[1..-1]
      end # model_merge_listener_path

      def self.model_apply_setter v, cid, value, sender
	case cid
	when Proc
	  nil
	when Array
	  # apply them in order
	  if sub = model_apply_cid(v, cid[0...-1]) 
	    model_apply_setter sub, cid[-1], value, sender
	  else
	    nil
	  end
	else
	  v.model_apply_setter cid, value, sender
	  true
	end
      end # model_apply_setter

    public # methods of Model

      # override
      def parent= parent 
	parent.addModel self
      end # parent=

      # the idea is to build a shared node tree like this:
      #   []
      # add_listener [a]
      #	  [a]
      # add_listener [a, b, c]
      #	  [[a, b]]
      #	  [[a, [b, c]]]
      # add_listener [a, d]
      #	  [[a, [b, c], d]]
      # add_listener [a, d, e]
      #	  [[a, [b, c], [d, e]]]
      # add_listener [a, b, f]
      #	  [[a, [b, c, f], [d, e]]]
      # add_listener [g]
      #	  [[a, [b, c, f], [d, e]], g]
      # ETC.
      def model_add_listener path
	#tag "model_add_listener(#{path.inspect})"
	Model::model_merge_listener_path @model_listeners, path
	tag "listeners=(#{@model_listeners.inspect})"
	model_init_path path
      end # model_add_listener

      def model_push_data value, sender, controlpath
	tag "model_push_data(#{value}, #{sender}, #{controlpath})"
	v = self
	cidpath = []
	lastcontrol = controlpath[-1]
	controlpath[0...-1].each do |control|
	  v &&= Model::model_apply_connector v, control, cidpath
	end
	tag "lastcontrol=#{lastcontrol}, cid=#{(lastcontrol && lastcontrol.connector).inspect}"
	tag "v = #{v.inspect}"
	if v && lastcontrol && cid = lastcontrol.connector
	  cidpath << cid
	  tag "cidpath=#{cidpath.inspect}"
	  tag "lastcontrol=#{lastcontrol}, cid=#{cid}"
	  if Model::model_apply_setter v, cid, value, sender 
	    tag "setter was applied, now propagate change"
	    model_propagate cidpath, value, sender
	  end
	end
      end

      def model_apply_setter methodname, value, sender
	tag "model_apply_setter(#{methodname.inspect}, #{value.inspect}, #{sender})"
	methodname = methodname.to_s
	methodname = methodname[0...-1] if methodname[-1] == '?'
	send(methodname + '=', value)
      end # model_apply_setter

      def model_apply_getter methodname
	# return self if methodname == :self	
	# since 'self' cannot be a method,
	# but 'self=' can!
	# Actually 'self' can be a method, but this seems crazy.
	send methodname
      end

  end # class Model

end # module R::Qt

if __FILE__ == $0
require 'reform/app'
Reform::app {
  # data X is a shortcut for 'rubydata { data X }'
  data 'Hallo World!'
  widget {
    name 'bert'
    # we connect 'title' to 'data.self', which is 'data' itself.
    # 'connector' will look upwards in the widgettree, and uses
    # the first model it finds
    title connector: :self 
  }
} # app
end

