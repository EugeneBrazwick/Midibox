#!/usr/bin/ruby -w

module RRTS

  require_relative '../rrts'
  require_relative 'node'

  module Node
    class YamlIOReader < EventsNode
      private
      def initialize io, options = {}
      end
    end
    
    class YamlFileReader < YamlIOReader
      private
      def initialize filename
        super(File.new(filename, 'r'))
      end
    end
    
    class YamlPipeReader < YamlIOReader
      private
      def initialize io = STDIN
        case io
        when String, Array
          io = IO.popen(io, 'r')
          options[:auto_close] = true
        when Integer
          io = IO.open(io, 'r')
          options[:auto_close] = true
        when IO
        else
          raise RRTSError.new("Cannot open '#{io}'")
        end
        options[:internalize] ||= false
        super
      end
    end
  end
end