
#  Copyright (c) 2013 Eugene Brazwick

require_relative 'control'

module R::Qt
  class Model < Control

    private # methods of Model

      def initialize *args
	super
	# listener tree, see add_listener
	@model_listeners = [] 
      end # initialize

      # context: model_init_path and model_push_data.
      # Delegates to model_apply_cid
      def self.model_apply_connector v, control, cidpath = nil
	model_apply_cid v, control && control.connector, cidpath
      end # model_apply_connector

      def self.model_apply_cid v, cid, cidpath
	#tag "model_apply_cid on #{v}, cid = #{cid.inspect}"
	case cid
	when NilClass
	  #tag "nil"
	  v
	when Proc
	  #tag "Passing #{v.class} #{v} to proc #{cid}"
	  cid[v]
	when Array
	  #tag "Array, apply them in order"
	  cid.inject(v) do |w, nm|
	    w and model_apply_cid w, nm, cidpath
	  end
	else
	  #tag "should be symbol, delegate to model_apply_getter"
	  cidpath << cid if cidpath
	  if cid == :self
	    # since v may not even have model_apply_getter
	    v
	  else
	    model_apply_getter v, cid
	  end
	end # case
      end # model_apply_cid

      # this works. But self inside any method still is the keyword.
      # Using this we don't need to hack the ':self' cid, at least
      # for reading.
      def self
	self
      end

      # context: model_propagate_i <- model_propagate
      # delegates to control.apply_model unless control == sender
      # cidpath: an array of cids that indicates the altered value within the model. It is how 
      #		 sender connects to us.
      #		 Or nil, implying a broadcast to all listeneres no matter what cid.
      # control: subject of the propagation algo
      # cid: normally control.connector
      # sender: original sender (some control) of datachange. Can be the model itself too.
      # v: starts out as the model, but we keep applying the cid on it as we go deeper
      # subs: model_listeners
      def self.model_propagate_cid cidpath, control, cid, sender, v, subs
	if sender.trace_propagation
	  $stderr.puts "PROPAGATE_CID(#{cidpath.inspect}, #{cid.inspect}, on #{v}, subs = #{subs})"
	end
	case cid
	when NilClass
	when Proc
	  cidpath = nil
	  v = cid[v]
	when Array
	  cid.each do |el|
	    v &&= model_propagate_cid cidpath, control, el, sender, v, subs
	  end
	  return v
	else
	  if cidpath
	    unless cidpath[0] == cid
	      #tag "cid conflict #{cid} vs #{cidpath[0]}, STOP propagation"
	      return nil 
	    end
	    # BAD IDEA cidpath.shift,  this alters the caller
	    cidpath = if cidpath.length == 1 then nil else cidpath[1..-1] end
	  end
	  # special case 'self':    v obviously need not change. THIS IS VERY WRONG!!!
	  # model_apply_getter may check for :self and return something different.
	  #tag "#{v}::model_apply_getter #{cid}"
	  v = model_apply_getter v, cid 
	  #tag "-> #{v}"
	end
	if subs
	  #tag "propagate to subs #{subs.inspect}"
	  model_propagate_i cidpath, sender, v, subs
	else
	  if v && !control.equal?(sender)
	    #tag "ARRIVAL at accepting endpoint #{control}, v = #{v}"
	    control.apply_model Model::model_unwrap v
	  end
	end
	v
      end # model_propagate_cid

    protected # methods of Model

    # cidpath is an array of cids. This shows how ichanged 'value' fits 
    # into this model. A listener must have this cidpath as a prefix, or
    # it must contain a Proc cid.  For this reason cidpath can be nil and
    # we must then broadcast.
    #
    # value is the new value. Do not use. This should describe the change
    # better.
    #
    # sender is the control that instigated the change. We must skip it 
    # when sending a message (but not its children).
    # This can be the model itself as well.
    #
    # listeners are the receivers as listenertree. It is always an array. 
    # See model_merge_listener_path.
    # Note we must not change the model, that's already been done.
    # We must inform all controls that connect to cidpath and reattach
    # by calling control.apply_model
    #
    # Context: model_propagate
    # Delegates to model_propagate_cid
      def self.model_propagate_i cidpath, sender, v, listeners
	if sender.trace_propagation
	  $stderr.puts "PROPAGATE(#{cidpath.inspect}, on #{v}, listeners = #{listeners})"
	end
	listeners.each do |listener|
	  if Array === listener 
	    control, *subs = listener
	  else
	    control, subs = listener, nil
	  end
	  #tag "control = #{control}"
	  model_propagate_cid cidpath, control, control.connector, sender, v, subs
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
	  if v.respond_to?(:model_apply_setter)
	    #tag "#{v} responds to 'model_apply_setter' so call it using #{cid}="
	    v.model_apply_setter cid, value, sender
	  else
	    v.send "#{cid}=", value
	  end
	  true
	end
      end # model_apply_setter

      def self.model_unwrap value
	v = value.model_value
      rescue NoMethodError
	value
      end
    public # methods of Model

    # context: model_push_data, delegates to model_propagate_i
    # also from Control.setup
    # cidpath can be an array, but normally it's just the initiating method.
    # cidpath can be nil or :broadcast to broadcast.
    # sender is the control that instigated the propagation, which can be the model
    # itself too (which is also the default).
      def model_propagate cidpath = nil, sender = nil 
	#tag "#{self}::model_propagate"
	cidpath = nil if cidpath == :broadcast
	cidpath = [cidpath] unless Array === cidpath || cidpath == nil
	Model::model_propagate_i cidpath, sender || self, self, @model_listeners
      end

      # override
      def parent= parent 
	#tag "calling #{parent}.addModel(#{self})"
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
	#tag "listeners=(#{@model_listeners.inspect})"
	# model_init_path path	  STUPID, since a single control can easily have 6 listeners.
	# AND it requires special API
      end # model_add_listener

      # Context: Control.push_data
      # controlpath is the list of controls starting with the one owning the model, and ending with
      # the original sender.
      def model_push_data value, controlpath
	sender = controlpath[-1]
	$stderr.puts "model_push_data(#{value}, #{sender}, #{controlpath})" if sender.trace_propagation
	v = self
	cidpath = []
	controlpath[0...-1].each do |control|
	  v &&= Model::model_apply_connector v, control, cidpath
	end
	#tag "sender=#{sender}, cid=#{(sender && sender.connector).inspect}"
	#tag "v = #{v.inspect}"
	if v && sender && cid = sender.connector
	  cidpath << cid
	  #tag "cidpath=#{cidpath.inspect}"
	  #tag "sender=#{sender}, cid=#{cid}"
	  if Model::model_apply_setter v, cid, value, sender 
	    #tag "setter was applied, now propagate change"
	    model_propagate cidpath, sender
	  end
	end
      end # model_push_data

      def model_apply_setter methodname, value, sender
	if sender.trace_propagation
	  $stderr.puts "model_apply_setter(#{methodname.inspect}, #{value.inspect}, #{sender})"
	end
	methodname = methodname.to_s
	methodname = methodname[0...-1] if methodname[-1] == '?'
	send(methodname + '=', value)
      end # model_apply_setter

      # apply 'methodname' as a 'getter'. The default uses 'send' since that likely works.
      # But some models may delegate it (and 'send' is hard to delegate).
      def model_apply_getter methodname
	# return self if methodname == :self	
	# since 'self' cannot be a method,
	# but 'self=' can!
	# Actually 'self' can be a method, but this seems crazy.
	send methodname
      end

      def self.model_apply_getter value, methodname
	if value.respond_to?(:model_apply_getter)
	  #tag "value #{value} responds to :model_apply_getter so call it"
	  value.model_apply_getter methodname
	elsif methodname == :self
	  value
	else
	  value.send methodname
	end
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

