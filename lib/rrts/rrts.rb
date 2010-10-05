
require_relative 'driver/alsa_midi.so'

module RRTS

  # Exception class to distinguish with ordinary runtime errors
  class RRTSError < RuntimeError
  end

  # Set up a scope (namely the passed block) in which tracing is active.
  def trace onoff = true
    if onoff
      set_trace_func -> event, file, line, id, binding, classname do
        printf "%8s %s:%-2d %-15s %-15s\n", event, file, line, classname, id
      end
      if block_given?
        begin
          yield
        ensure
          set_trace_func nil
        end
      end
    else
      set_trace_func nil
    end
  end

  # tag automagically prints the file+linenr where it was, for easy removal
  # Apart from that it is the same as +puts+
  def tag msg = ''
    # avoid puts for threading problems
    STDERR.print "#{caller[0]} #{msg}\n"
  end

  # Special tag that prints TODO + msg on STDERR
  def todo msg = nil
    tag 'TODO' + (msg ? ': ' + msg : '')
  end

  # prints a NIY message on stderr
  def niy msg = ''
    tag 'NOT IMPLEMENTED YET' + (msg ? ': ' + msg : '')
  end
end # module RRTS
