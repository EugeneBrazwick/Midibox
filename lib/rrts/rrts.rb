
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

end
