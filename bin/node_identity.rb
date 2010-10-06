#!/usr/bin/ruby

module RRTS

  module Nodes

    require 'rrts/node/node'

=begin SOME THOUGHTS

the --clientname option is weird. We may start a nr of sequencers after all.

It seems that creating an Alsa sequencer X will close a previous seq X
Or we should 'dip in' the namespace and use X instead of recreating it.
=end

#
# Identity is a class that just attaches an input to an output.
# Functionality is gained by using specific input- and outputoptions
#
# Examples:
#   Identity.new '--input=song.yaml', '--output='20:1'
#   Identity.new '--input=UM-2 MIDI 1', '--output=song.yaml.gz'
#   Identity.new '--input=song.midi', '--output=song.ygz'
#
# Extensions understood:
#     .mid
#     .midi
#     .yaml
#     .yaml.gz
#     .ygz
#
# Anything else is treated as a portidentifier.
    class Identity < Node::Filter
      private
      def initialize *options
        super()
        require_relative '../lib/rrts/node/defoptions'
#         tag "Parsing options #{options.inspect}"
        unless options.empty?
          # THIS IS A MESS. How does *options work???
          if options.count == 1
            if Node::DefaultOptions === options[0]
              options = options[0]
            elsif Array === options[0]
              options = Node::DefaultOptions.new(options[0])
            else
              options = Node::DefaultOptions.new(options)
            end
          else
            options = Node::DefaultOptions.new(options)
          end
        else
          options = Node::DefaultOptions.new(ARGV)
        end
#         tag "done parsing"
        @in = options.input_node
#         tag "get output node"
        @out = options.output_node
#         tag "connect"
        @in >> @out
#         tag "DONE"
      end
      public

      # three delegators
      def produce
        @in.produce
      end

      def run
        @in.run
      end

      def each &block
        return to_enum unless block
        @in.each(&block)
      end

#       def consume producer, &when_done
#       end
    end

    I = Identity
  end # module Nodes
end #RRTS

if __FILE__ == $0
#   GC.stress = true                    THE END OF EVERYTHING....
  include RRTS
  include Nodes
=begin
  require_relative '../lib/rrts/node/defoptions'
  I.new(Node::DefaultOptions.new(['-i', '../fixtures/eurodance.midi',
                                  '-o', '/tmp/eurodance.ygz'])).run
  I.new(Node::DefaultOptions.new(['-i', '/tmp/eurodance.ygz', '-o', '20:1'])).run
=end
  # using ARGV here:
  begin
    I.new.run
  rescue Interrupt
  end
#   tag "GC.count = #{GC.count}"
end