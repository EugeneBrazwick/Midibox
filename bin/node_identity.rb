#!/usr/bin/ruby

module RRTS

  module Nodes

    require_relative '../lib/rrts/node/node'

=begin rdoc

Identity is a class that just attaches an input to an output.
Functionality is gained by using specific input- and outputoptions

Examples:
  Identity.new input: 'song.yaml', output: '20:1'
  Identity.new input: 'UM-2 MIDI 1', output: 'song.yaml.gz'
  Identity.new input: 'song.midi', output: 'song.ygz'

Extensions understood:
    .mid
    .midi
    .yaml
    .yaml.gz
    .ygz

Anything else is treated as a portidentifier.
=end
    class Identity < Node::EventsNode
      private
      def initialize options = nil
        # how are options processed. Should be possible to use DefaultOptions
        # but they use ARGV.
        # With no options it connects stdin to stdout using yaml... Which is indeed stupid.
        unless options
          require_relative '../lib/rrts/node/defoptions'
          options = Node::DefaultOptions.new([])
        end
        @in = options.input_node
        @out = options.output_node
      end
      public
      def run
        @out.connect_to @in
      end

      def each &block
        @io.each &block
      end
    end

    I = Identity
  end # module Nodes
end #RRTS

if __FILE__ == $0
  include RRTS
  include Nodes
  require_relative '../lib/rrts/node/defoptions'
  I.new(Node::DefaultOptions.new(['-i', '../fixtures/eurodance.midi',
                                  '-o', '/tmp/eurodance.ygz'])).run
  I.new(Node::DefaultOptions.new(['-i', '/tmp/eurodance.ygz', '-o', '20:1'])).run
end