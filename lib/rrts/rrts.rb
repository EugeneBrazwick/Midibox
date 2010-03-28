
require_relative 'driver/alsa_midi.so'

module RRTS
  RRTSError = RuntimeError

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

  def tag msg = ''
    # avoid puts for threading problems
    STDERR.print "#{caller[0]} #{msg}\n"
  end

  def todo msg = ''
    tag 'Todo: ' + msg
  end

  def niy
    tag 'Not implemented yet: ' + msg
  end
end
