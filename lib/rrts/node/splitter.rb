
require_relative 'node'

module RRTS

  module Node

    # a consumer made of ... more consumers.
    class Identity < Consumer
      public

        #override. Merges in the code of Producer#run_thread
        def consume producer, &when_done
          # create the subfibers:
          cons = @consumers.map { |consumer| consumer.consume(self) }
          cons.delete(nil) # how did these get in???
          return nil if cons.empty?   # will not send events
          each_fiber(when_done) do |ev|
            cons.each { |out| out.resume ev }
          end
        end

    end # again, this was almost too easy....

# Splitter make it possible of associating several consumer with a single filter.
# As such it resembles a 'MultiFilter'.
# Splitter can also be created by stacking up Filters on top of one another
# but this would be rather complicated.
# For example a channelsplitter cannot just be a ch==1 + ch==2 condition in
# series as the second filter would obviously never receive any events.
#
# Internally it uses a different structure than Base.
# We use a hash with key: the condition, and value: the ConsumerBlade stuck to it.
#
# IMPORTANT: conditions do not work as hashkeys. So I decided that name is required.
    class Splitter < Consumer

        class Split < Identity
          private
            def initialize name, &condition
              super()
              @name, @condition = name, condition
            end

          public

            attr :name
            attr :condition

        end

      private

        def initialize producer = nil, options = nil
          super
          @splitters = {}
        end

      public

        def condition(name, &block)
#           tag "splitters = #@splitters"
          s = @splitters[name] and return s
          @splitters[name] = Split.new(name, &block)
        end

        def consume producer, &when_done
          cons = {}
          @splitters.each do |k, split|
            cons[k] = split.consume(self)
          end
          return nil if cons.empty?
          each_fiber(when_done) do |ev|
            if ev.nil?
              # this is an obligation and inconvenient for handle_event overrides
              cons.each_value { |out| out.resume nil }
            else
              cons.each do |name, fib|
#                 tag "calling handle_event #{ev}, based on #{@splitters.inspect}"
                fib.resume(ev) if @splitters[name].condition.(ev)
              end
            end
          end
        end

        alias :[] :condition
    end # class Splitter

  end # Node
end # RTTS
