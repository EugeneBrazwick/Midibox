#!/usr/bin/ruby

# basicly Enumerator WITH peek then
class EventStream

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

  alias :first :peek

  def <=> other
    peek <=> other.peek
  end
end

=begin
This priority queue works on enumerators and it dequeues
the first element of the first enumerator.
Enqueued is the full enumerator, not a single entry.
Each is important that each enumerator is already sorted.

enqueue [4,4, 8, 12]
enqueue [5, 6,6 24]

dequeue* -> 4,4,5,6,6,8,12,24

To make it easier the internals use a main hub, called the Tree
but other nodes are PriorityNodes. The tree has a single node
and caches the first enum.
The nodes have a single enum, and a left and right branch.

enqueue and dequeue on nodes return a replacement node for
the node they were called upon.
=end
class PriorityNode
  private
  def initialize enumerable
    @enum = EventStream.new enumerable
    @left = @right = nil
  end

  # returns a replacement for self
  # Note that replacement for self cannot have an empty enumerator!
  def reorder
    # now left or right takes over... or not
    peek = @enum.peek rescue nil
    r = self
#     puts "#{File.basename(__FILE__)}:#{__LINE__}: Node::dequeue peek=#{peek}"
    if @left
      if !peek || @left.peek < peek
        if @right && @right.peek < @left.peek
          r, @right = @right, nil
#           puts "whoops right must become root"
          r.enqueue self if peek
        else
#           puts "whoops left must become root"
          r, @left = @left, nil
          r.enqueue self if peek
        end
      end
    elsif @right && @right.peek < peek
      r, @right = @right, nil
#       puts "whoops right must become root, since there is no left"
      r.enqueue self if peek
    end
    #     puts "dequeue returns @enum=#@enum, enum=#{enum}"
    r
  end

  protected

  attr :left, :right

  public

  # this is the 'next' element within the enumerable
  def peek
    @enum.peek
  end

  attr :enum

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
end

class PriorityTree
  private
  def initialize
    @node = nil
  end

  public

  def enqueue enumerable
    n = PriorityNode.new(enumerable)
    @node = @node ? @node.enqueue(n) : n
#     puts "enqueue node is now #{@node.inspect}"
  end

  def dequeue
    return nil unless @node
    @node, result = @node.dequeue
#     puts "#{File.basename(__FILE__)}:#{__LINE__}: dequeue node is now #{@node.inspect}"
    result
  end

  def peek
    @node && @node.peek rescue nil
  end
end

if $0 == __FILE__
  e = [1, 2, 3, 4]
  i = EventStream.new(e)
  puts "i.first=#{i.first}"
  i.next
  puts "i.first=#{i.first}, i.next=#{i.next}"
  p = PriorityTree.new
  # Don't get confused. a and b are single entries in our queue.
  a = [1, 1, 4, 8, 21, 21, 21, 32]
  b = [0, 1, 2, 8, 8, 21, 22, 45, 65 ]
  p.enqueue(a)
  p.enqueue(b)
  p.enqueue([-4, 12, 28, 45, 46])
  print "->"
  loop do
    print " ***#{p.peek}*** "
    r = p.dequeue
#     puts "#{File.basename(__FILE__)}:#{__LINE__}: r = #{r}"
    break unless r
  end
  puts
end
