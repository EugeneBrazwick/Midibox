
require_relative 'driver/alsa_midi.so'

# This module is the namespace for the entire MIDI API.
#
# RRTS originally stood for Ruby RealTime Sequencer. But how RT can it be?
# Currently it contains the Alsa (Advanced Linux Sound Architecture) MIDI Driver
# plus supporter classes, in particular Sequencer.
#
# The following rules were used:
# - This is a literal implementation of the almost full alsa snd_seq API
# - functions have been made methods by using arg0 as +self+.
# - the +snd_seq_+ prefix was removed for methods, but not for constants.
# - special case seq_open for snd_seq_open, since just +open+ would conflict with
#   Kernel#open.
# - the support classes have methods that do not require the Alsa constants anymore,
#   however theses constants are still available in the RRTS::Driver namespace.
# - obvious default values for parameters are applied, whereas the original API is C,
#   which has no defaults to begin with.
# - where values are often used as pairs (or even a c-struct) as in client+port=address
#   I allow passing these as a tuple (array with elements at 0 and 1).
# - similarly, instances of the Driver classes can be used, or even the higher level
#   classes (not always) where the original API expects the id or handle to be passed.
#   This is always the case for queueids, where AlsaMidiQueue_i can be used, or for portids
#   where AlsaMidiPort_i can be used.
# - methods starting with 'set_' (snd_seq_..._set) with a single (required) argument have been
#   replaced by the equivalent setter in ruby (as 'port=')
# - +set+ methods with 0 or 2 or more arguments still remain
# - for methods starting with 'get_' this prefix has been removed as well.
# - names for getters that return a boolean are suffixed with '?'.
# - errors became exceptions, in particular AlsaMidiError and ENOSPC somewhere.
#   Exceptions on this rule are methods used in finalizers, since exceptions in finalizers
#   are really not funny. So close/free/clear or whatever return their original value.
#   This also implies the errorcode returnvalue was abolished.
# - integer arguments and returnvalues that could be (or should be) clearly interpreted as booleans
#   have been replaced by true booleans.
# - methods with a argumentaddress in C (Like 'int f(int *result)') are altered to return this parameter
#   (so f -> [int, int]).
#   In some cases this leads to returning a tuple.
# - methods that would always return nil (though the original may not) now return +self+.
# - in some cases, some parameters became meaningless.
# - normally in C, you would operate on the event object direct, using the structure definition.
#   As in 'event.value = 23'
#   This is no longer possible, but where names where unique within the union they became
#   setters and getters. So event.value = 23 is still valid ruby.
#   For ambiguous situations, the same approach is chosen, but the backend uses
#   the type as set in the event.
#   So:
#      ev = ev_malloc
#      ev.channel = 7
#   is wrong as the type is not yet set and we must choose between ev.data.note.channel or
#   ev.data.control.channel.
#   But:
#      ev = ev_malloc
#      ev.note = 63
#   is perfectly OK, since the +note+ selector is unambiguous (ev.data.note.note).
#   The solution for the 'channel' case would then be:
#      ev = ev_malloc
#      ev.type = SND_SEQ_EVENT_NOTE
#      ev.channel = 7
# - in some cases, alsa uses ambiguous names. For example, the macro +snd_seq_ev_set_source+ only sets
#   the port, and not the client.
#   This has been renamed to +source_port+, and +source_client+ is similar. Then the +source+
#   setter and getter remain and they refer to the tuple client plus port.
#   However for 'queue' this would not work, so
#   +ev.queue+ refers to the queue on which the event was send or received while
#   +ev.queue_queue+ refers to the queue as a subject of a queue control event
# - all other queue params have a 'queue_' prefix, including value.
#   Example: +ev.data.queue.param.value+  should be replaced with +ev.queue_value+.
# - I have decided that nonblocking IO will cause the +EAGAIN+ systemerror to be raised, whenever this is
#   appropriate. However the +output_event+ call can't always do this since it would cause events
#   to be partly transmitted in some cases. So this call will always block.
#   All functions that may block now (read: should) use +rb_thread_blocking_region+. Blocking mode
#   should therefore really be on, as this is much easier, and I don't really see any use of
#   nonblocking mode anymore.
#   Here is a list of all blocking methods:
#   - snd_seq_event_input
#   - snd_seq_event_output
#   - snd_seq_drain_output
#
# *IMPORTANT*: using this API as is, will not be the most efficient way to deal with
# alsa_midi.so.  Please use the ruby classes and additional methods in this library.
# See alsa_midi++.cpp
# This yields in particular for the MidiEvent API since the only way to write or read
# a field is through a wrapped method. Even more, the C API has a lot of macros that
# are now implemented as ruby methods. Again, this is not efficient.
# However, it implies that existing programs can easily be ported, see for instance
# rrecordmidi.rb which is a 1 on 1 port of arecordmidi.c.
# Same for rplaymidi.rb
#
# The 'revents' method is rather vague and the examples do not use it. What is the timeout?
# Or isn't there any?  Anyway, the result is made consistent with that of poll.
#
# ===Some things about certain parameters
#
# ====connections
#
# represented by RRTS::MidiPort or by a splat or tuple [clientid, portid]
# or by a string that uses the port name like 'MIDI UM-2'.
#
# ====realtimes
#
# represented by a float which is simple the number of seconds, or by a tuple
# or splat [seconds, nanoseconds]
#
# Note that some methods also except times in ticks if the value is an integer.
# So 35 is that much ticks, and not that much seconds, that would be 35.0(!)
#
# === ids
#
# In case a method accepts an id, it always accepts the representing instance also.
# So you can pass a RRTS::MidiQueue where a queueid is expected etc..
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
