#!/usr/bin/ruby

module RRTS

  # basicly Enumerator WITH peek then. Ruby 1.9.2 or higher won't need this code anymore
  class MyEnumerator

    private
    def initialize array
      @ptr = 0
      @array = array
    end

    public
    def next
      raise StopIteration.new if @ptr >= @array.length
      r = @array[@ptr]
      @ptr += 1
      r
    end

    def peek
      @array[@ptr]
    end

    # therefore, it is a 'relative' first.
    alias :first :peek

    def <=> other
      peek <=> other.peek
    end

    attr :array
  end

  class PriorityNode
    private
    def initialize enumerable
      @enum = MyEnumerator.new enumerable
      @left = @right = nil
    end

    protected

    # returns a replacement for self
    # Note that replacement for self cannot have an empty enumerator!
    def reorder
#       puts "#{File.basename(__FILE__)}:#{__LINE__}: reorder"
      peek = @enum.peek rescue nil
      r = peek && self
#       puts "#{File.basename(__FILE__)}:#{__LINE__}: Node::reorder peek=#{peek}, left=#{@left && @left.peek}, right=#{@right && @right.peek}"
      if @left
        if !peek || @left.peek < peek
          raise RRTSError.new("crapcode") if @right && @right.enum && !@right.peek
          if @right && @right.peek < @left.peek
            @enum, @right.enum = @right.enum, @enum
            @right = @right.reorder
            raise RRTSError.new("crapcode") if @right && !@right.enum
          else
#             puts "whoops left must become root"
            if peek
              @enum, @left.enum = @left.enum, @enum
              @left = @left.reorder
              raise RRTSError.new("crapcode") if @left&& !@left.enum
            else
              r, @left = @left, nil
              r.enqueue(@right) if @right
              raise RRTSError.new("crapcode") unless r.enum
            end
          end
        end
      elsif @right && @right.peek < peek
        if peek
          @enum, @right.enum = @right.enum, @enum
          @right = @right.reorder
          raise RRTSError.new("crapcode") if @right && !@right.enum
        else
          r, @right = @right, nil
#           puts "whoops right must become root, since there is no left"
          r.enqueue(@left) if @left
          raise RRTSError.new("crapcode") unless r.enum
        end
      end
      r
    end

    attr :left, :right

    public

    # this is the 'next' element within the enumerable, but the queue is not altered
    def peek
      @enum.peek
    end

    attr_accessor :enum

    # for internal use
    def next
      @enum.next
    end

    # returns replacement node
    def enqueue node
      if peek > node.peek # passed node is smaller than current head
        node.enqueue self
        return node
      end
      if @left
        if @right
          if @right.peek > @left.peek
            @right = @right.enqueue node
          else
            @left = @left.enqueue node
          end
        else @right = node
        end
      else @left = node
      end
      self # we remain king
    end

    def dequeue
      r = @enum.next
      return reorder, r
    end

    def array
      @enum && @enum.array
    end
  end

=begin
  This priority queue (PriorityTree) works on enumerators and it dequeues
  the first element of the first enumerator.
  It is used to keep track of the first event present if we are supplied
  with several streams (enumerables) of them.

  Enqueued is the full enumerator, not a single entry.
  It is important that each enumerator is already sorted. Since supposedly
  these are tracks with events in order that should just be the case.

  enqueue [4, 4, 8, 12]
  enqueue [5, 6, 6, 24]

  dequeue* -> 4, 4, 5, 6, 6, 8, 12, 24

  To make it easier the internals use a main hub, called the Tree
  but other nodes are PriorityNodes. The tree has a single node
  and caches the first enum.
  The nodes have a single enum, and a left and right branch.

  enqueue and dequeue on nodes return a replacement node for
  the node they were called upon.
=end
  class PriorityTree
    private
    def initialize
      @node = nil
    end

    public

    # enqueue a list of elements
    def enqueue enumerable
      n = PriorityNode.new(enumerable)
      @node = @node ? @node.enqueue(n) : n
  #     puts "enqueue node is now #{@node.inspect}"
    end

    # dequeue the first event from all the tracks enqueued.
    def dequeue
      return nil unless @node
      array = @node.array
      @node, result = @node.dequeue
  #     puts "#{File.basename(__FILE__)}:#{__LINE__}: dequeue node is now #{@node.inspect}"
      return result, array
    end

    # get the first event (as in dequeue) but do not alter the queue
    def peek
      @node && @node.peek rescue nil
    end

    # Erm.... ?????
    def array
      @node.array
    end
  end

end # RRTS

if $0 == __FILE__
  include RRTS
  e = [1, 2, 3, 4]
  i = MyEnumerator.new(e)
  puts "i.first=#{i.first}"
  i.next
  puts "i.first=#{i.first}, i.next=#{i.next}"
  p = PriorityTree.new
  # Don't get confused. a and b are single entries in our queue.
  a = [1, 1, 4, 8, 21, 21, 21, 32]
  b = [0, 1, 2, 8, 8, 21, 22, 45, 65 ]
  p.enqueue(a)
  p.enqueue(b)
  p.enqueue [-4, 12, 28, 45, 46]
  p.enqueue [-4, 11, 11, 12, 28, 30, 45, 46, 46]
#   puts "p = #{p.inspect}"
  print "->"
  loop do
    print " #{p.peek}"
    r = p.dequeue
#     puts "#{File.basename(__FILE__)}:#{__LINE__}: r = #{r}"
    break unless r
  end
  puts
end
