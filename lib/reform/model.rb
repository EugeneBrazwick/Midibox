
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
	@model_listeners = {}

	# changelist. each key is a full keypath, expressed in indices,
	# that must be symbols or integers. 
	# Each value is a PropertyChange record
	@model_changes = {}
      end # initialize

      # every node in the path can have a connector set
      def model_init_path path
	v = self
	lastcontrol = nil
	path.each do |control|
	  lastcontrol = control
	  cid = control.connector and
	    v = v.model_apply_getter(cid)
	end
	lastcontrol.apply_model(v) if lastcontrol
      end # model_init_path

    protected # methods of Model

      def self.model_merge_listener_path listeners, path
	unless listener = listeners.find {|k, v| k == :key && v == path[0]}
	  listeners[:key] = path[0]
	  listeners[:value] = nil
	end
	path = path[1..-1]
	return if path.empty?
	listeners[:value] ||= {}
	model_merge_listener_path listeners[:value], path
      end # model_merge_listener_path

    public # methods of Model

      # override
      def parent= parent 
	parent.addModel self
      end # parent=

      # the idea is to build a shared node tree like this:
      # add_listener [a]
      #	  {a=>nil}
      # add_listener [a, b, c]
      #	  {a=>{b=>{c=>nil}}}
      # add_listener [a, d]
      #	  {a=>{b=>{c=>nil}}, d=>nil}
      # add_listener [a, d, e]
      #	  {a=>{b=>{c=>nil}}, d=>{e=>nil}}
      # add_listener [a, b, f]
      #	  {a=>{b=>{c=>nil, f=>nil}, d=>{e=>nil}}}
      # add_listener [g]
      #	  {a=>{b=>{c=>nil, f=>nil}, d=>{e=>nil}}, g=>nil}
      def model_add_listener path
	#tag "model_add_listener(#{path.inspect})"
	Model::model_merge_listener_path @model_listeners, path
	#tag "listeners=(#{@model_listeners.inspect})"
	model_init_path path
      end # model_add_listener

  end # class Model

end # module R::Qt

if __FILE__ == $0
require 'reform/app'
Reform::app {
  data 'Hallo World!'
  widget {
    name 'bert'
    title connector: :self 
  }
} # app
end

