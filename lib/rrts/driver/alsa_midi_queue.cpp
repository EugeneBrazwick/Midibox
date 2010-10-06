
#pragma implementation

#include "alsa_midi_queue.h"
#include "alsa_midi.h"

#if defined(DUMP_API)
#define DUMP_STREAM stderr
#endif

#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaQueueInfoClass, alsaQueueTempoClass, alsaQueueStatusClass;

/** Document-method: RRTS::Driver::AlsaQueueTempo_i#copy_to
call-seq: copy_to([other = nil]) -> clone

Makes a copy of the current tempo. If +other+ is not specified it
returns a copy, otherwise +other+ is used to copy +self+ into.
*/
ALSA_MIDI_COPY_TO_TEMPLATE(queue_tempo, QueueTempo)

/** Document-method: RRTS::Driver::AlsaQueueStatus_i#copy_to
call-seq: copy_to([other = nil]) -> clone

Makes a copy of the current queuestatus. If +other+ is not specified it
returns a copy, otherwise +other+ is used to copy +self+ into.
*/
ALSA_MIDI_COPY_TO_TEMPLATE(queue_status, QueueStatus)

/** Document-method: RRTS::Driver::AlsaQueueInfo_i#copy_to
call-seq: copy_to([other = nil]) -> clone

Returns a copy of the queue info structure. If +other+ is given it will be used
as a buffer, otherwise a new buffer is allocated
*/
ALSA_MIDI_COPY_TO_TEMPLATE(queue_info, QueueInfo)

/** call-seq: flags = someFlags

Alter the flags for this queue. Must be used before creating a queue.
God knows what these flags are. See the Alsa docs (but they won't tell you).
*/
static VALUE
wrap_snd_seq_queue_info_set_flags(VALUE v_qi, VALUE v_flags)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  snd_seq_queue_info_set_flags(qi, NUM2UINT(v_flags));
  return Qnil;
}

/** call-seq: locked = bool

I believe that queues are created locked, but you may lock or unlock them
with this method. This means that other clients can not alter its parameters,
like the timer
*/
static VALUE
wrap_snd_seq_queue_info_set_locked(VALUE v_qi, VALUE v_locked)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  snd_seq_queue_info_set_locked(qi, BOOL2INT(v_locked));
  return Qnil;
}

/** call-seq: name = string

Change the name of the queue to be (must be called before creating a queue)
*/
static VALUE
wrap_snd_seq_queue_info_set_name(VALUE v_qi, VALUE v_name)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_queue_info_set_name(%p, %s)\n", qi, RSTRING_PTR(v_name));
#endif
  snd_seq_queue_info_set_name(qi, StringValuePtr(v_name));
  return Qnil;
}

/** call-seq: queue() -> int

Returns: the queueid of the queue
*/
static VALUE
wrap_snd_seq_queue_info_get_queue(VALUE v_qi)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  return INT2NUM(snd_seq_queue_info_get_queue(qi));
}

/** call-seq: flags() -> int

Returns: some flags, but these are undocumented
*/
static VALUE
wrap_snd_seq_queue_info_get_flags(VALUE v_qi)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  return UINT2NUM(snd_seq_queue_info_get_flags(qi));
}

/** call-seq: name() -> string

Returns: the name of this queue
*/
static VALUE
wrap_snd_seq_queue_info_get_name(VALUE v_qi)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  return rb_str_new2(snd_seq_queue_info_get_name(qi));
}

/** call-seq: owner() -> int

Returns: the clientid of the owner. Normally this would be yourself
*/
static VALUE
wrap_snd_seq_queue_info_get_owner(VALUE v_qi)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  return INT2NUM(snd_seq_queue_info_get_owner(qi));
}

/** call-seq: locked?() -> bool

Returns: true if the queue is locked. But locked how or what?
*/
static VALUE
wrap_snd_seq_queue_info_get_locked(VALUE v_qi)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  return INT2BOOL(snd_seq_queue_info_get_locked(qi));
}

/** call-seq: owner = clientid

Set the owner client id of a queue_info container.

Parameters:
[owner] clientid or RRTS::MidiClient
*/
static VALUE
wrap_snd_seq_queue_info_set_owner(VALUE v_qi, VALUE v_owner_clientid)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_queue_info_set_owner(%p, %d)\n", qi, NUM2INT(v_owner_clientid));
#endif
  RRTS_DEREF_DIRTY(v_owner_clientid, @client);
  snd_seq_queue_info_set_owner(qi, NUM2INT(v_owner_clientid));
  return Qnil;
}

/** call-seq: ppq() -> int

Get the ppq (ticks per beat)
*/
static VALUE
wrap_snd_seq_queue_tempo_get_ppq(VALUE v_tempo)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  return INT2NUM(snd_seq_queue_tempo_get_ppq(tempo));
}

/** call-seq: queue() -> int

Get the queue id
*/
static VALUE
wrap_snd_seq_queue_tempo_get_queue(VALUE v_tempo)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  return INT2NUM(snd_seq_queue_tempo_get_queue(tempo));
}

/** call-seq: skew() -> int

Get the timer skew value. The skew_value/skew_base form the relative speed of the
queue and this ratio is normally 1
See RRTS::Driver::AlsaQueueTempo_i#skew_base
*/
static VALUE
wrap_snd_seq_queue_tempo_get_skew(VALUE v_tempo)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  return UINT2NUM(snd_seq_queue_tempo_get_skew(tempo));
}

/** call-seq: skew_base() -> int

Get the timer skew base value. By default this is 0x10000
See RRTS::Driver::AlsaQueueTempo_i#skew.
*/
static VALUE
wrap_snd_seq_queue_tempo_get_skew_base(VALUE v_tempo)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  return UINT2NUM(snd_seq_queue_tempo_get_skew_base(tempo));
}

/** call-seq: tempo() -> int

Get the tempo. This is (?) the number of microseconds per beat (quarternote)
So if ♩ = 60 then 1_000_000, and if ♩ = 120 then 500_000 etc..
*/
static VALUE
wrap_snd_seq_queue_tempo_get_tempo(VALUE v_tempo)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  return UINT2NUM(snd_seq_queue_tempo_get_tempo(tempo));
}

/** call-seq: ppq = value

Set the ppq (pulses per quarter). You would normally set this before creating
a queue.
*/
static VALUE
wrap_snd_seq_queue_tempo_set_ppq(VALUE v_tempo, VALUE v_ppq)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  snd_seq_queue_tempo_set_ppq(tempo, NUM2INT(v_ppq));
  return Qnil;
}

/** call-seq: skew = value
Change the skew value if value is an int. If it is a double then both
skew value and skew base are set so that skew/base == value.
*/
static VALUE
wrap_snd_seq_queue_tempo_set_skew(VALUE v_tempo, VALUE v_skew)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);

  VALUE v_dbl = rb_check_float_type(v_skew);
  if (RTEST(v_dbl))
    {
      const double t = NUM2DBL(v_dbl);
      snd_seq_queue_tempo_set_skew(tempo, int(t * 0x10000));
      snd_seq_queue_tempo_set_skew_base(tempo, 0x10000);
    }
  else
      snd_seq_queue_tempo_set_skew(tempo, NUM2UINT(v_skew));
  return Qnil;
}

/** call-seq: skew_base = value

Normally this is set to 0x10000. The ratio skew_value/skew_base is the relative speed of the
queue.
*/
static VALUE
wrap_snd_seq_queue_tempo_set_skew_base(VALUE v_tempo, VALUE v_skew)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  snd_seq_queue_tempo_set_skew_base(tempo, NUM2UINT(v_skew));
  return Qnil;
}

/** call-seq: tempo = something

I quote here the Alsa documentation:
"Set the tempo of a queue_status container."
So there it is...

It should be the beatlength in microseconds.
So it is 60_000_000 / bpm
bpm is aka qpm
The number of ticks per beat cannot be changed while the queue runs, but the tempo can be.
*/
static VALUE
wrap_snd_seq_queue_tempo_set_tempo(VALUE v_tempo, VALUE v_val)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  snd_seq_queue_tempo_set_tempo(tempo, NUM2UINT(v_val));
  return Qnil;
}

/** call-seq: queue() -> into

Returns: the queueid
*/
static VALUE
wrap_snd_seq_queue_status_get_queue(VALUE v_status)
{
  snd_seq_queue_status_t *status;
  Data_Get_Struct(v_status, snd_seq_queue_status_t, status);
  return INT2NUM(snd_seq_queue_status_get_queue(status));
}

/** call-seq: events() -> int

Returns: the number of events remaining in the queue
*/
static VALUE
wrap_snd_seq_queue_status_get_events(VALUE v_status)
{
  snd_seq_queue_status_t *status;
  Data_Get_Struct(v_status, snd_seq_queue_status_t, status);
  return INT2NUM(snd_seq_queue_status_get_events(status));
}

/** call-seq: tick_time() -> int

Returns: the current time/position in the queue (in ticks)
*/
static VALUE
wrap_snd_seq_queue_status_get_tick_time(VALUE v_status)
{
  snd_seq_queue_status_t *status;
  Data_Get_Struct(v_status, snd_seq_queue_status_t, status);
  return UINT2NUM(snd_seq_queue_status_get_tick_time(status));
}

/** call-seq: real_time -> [secs, nsec]

Returns: the current time/position in the queue as a tuple [seconds, nanoseconds]
*/
static VALUE
wrap_snd_seq_queue_status_get_real_time(VALUE v_status)
{
  snd_seq_queue_status_t *status;
  Data_Get_Struct(v_status, snd_seq_queue_status_t, status);
  const snd_seq_real_time * const t = snd_seq_queue_status_get_real_time(status);
  return rb_ary_new3(2, UINT2NUM(t->tv_sec), UINT2NUM(t->tv_nsec));
}

/** call-seq: status() -> int

Returns: something. 'status bits' says the Alsa doc. But which?
According to Eugene it is != 0 for a running queue.
*/
static VALUE
wrap_snd_seq_queue_status_get_status(VALUE v_status)
{
  snd_seq_queue_status_t *status;
  Data_Get_Struct(v_status, snd_seq_queue_status_t, status);
  return UINT2NUM(snd_seq_queue_status_get_status(status));
}

/** call-seq: running?() -> bool

Returns: status() != 0.
*/
static VALUE
wrap_snd_seq_queue_status_get_status_ex(VALUE v_status)
{
  snd_seq_queue_status_t *status;
  Data_Get_Struct(v_status, snd_seq_queue_status_t, status);
  return INT2BOOL((int)snd_seq_queue_status_get_status(status));
}

void
alsa_midi_queue_init()
{
  if (0)  // this is to make rdoc document it.
    {
      VALUE rrtsModule = rb_define_module("RRTS");
      alsaDriver = rb_define_module_under(rrtsModule, "Driver");
    }

  /** Document-class: RRTS::Driver::AlsaMidiQueue_i

  This wrapper is used for creating queues, and also for querying existing ones.

  Only if a queue is associated with an Alsa connection (see RRTS::Driver::AlsaPortInfo_i#timestamp_queue=)
  can notes received be timestamped, and notes send can be queued for emission on a very precise
  moment.

  A queue can operate as a recording or playback device. You can use queueevents to operate on the
  queue to start, pause and continue it, or you can set the position (time) to a specific value
  causing events to be skipped or replayed.

  To get a queueinfo use RRTS::Driver::AlsaSequencer_i#queue_info
  */
  alsaQueueInfoClass = rb_define_class_under(alsaDriver, "AlsaQueueInfo_i", rb_cObject);

  /** Document-class: RRTS::Driver::AlsaQueueTempo_i

  This wrapper is used for setting and retrieving tempo information.
  To get the tempo use RRTS::Driver::AlsaSequencer_i#queue_tempo
  */
  alsaQueueTempoClass = rb_define_class_under(alsaDriver, "AlsaQueueTempo_i", rb_cObject);

  /** Document-class: RRTS::Driver::AlsaQueueStatus_i

  This wrapper is used for retrieving the current 'time' of the queue.
  To get the tempo use RRTS::Driver::AlsaSequencer_i#queue_status
  */
  alsaQueueStatusClass = rb_define_class_under(alsaDriver, "AlsaQueueStatus_i", rb_cObject);

  rb_define_method(alsaQueueTempoClass, "tempo=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_set_tempo), 1);
  rb_define_method(alsaQueueTempoClass, "usecs_per_beat=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_set_tempo), 1);
  rb_define_method(alsaQueueTempoClass, "ppq=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_set_ppq), 1);
  rb_define_method(alsaQueueTempoClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_copy_to), -1);
  rb_define_method(alsaQueueTempoClass, "skew=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_set_skew), 1);
  rb_define_method(alsaQueueTempoClass, "skew_base=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_set_skew_base), 1);
  rb_define_method(alsaQueueTempoClass, "skew_base", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_get_skew_base), 0);
  rb_define_method(alsaQueueTempoClass, "skew", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_get_skew), 0);
  rb_define_method(alsaQueueTempoClass, "ppq", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_get_ppq), 0);
  rb_define_method(alsaQueueTempoClass, "tempo", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_get_tempo), 0);
  rb_define_method(alsaQueueTempoClass, "usecs_per_beat", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_get_tempo), 0);
  rb_define_method(alsaQueueTempoClass, "queue", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_get_queue), 0);

  rb_define_method(alsaQueueInfoClass, "flags=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_set_flags), 1);
  rb_define_method(alsaQueueInfoClass, "locked=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_set_locked), 1);
  rb_define_method(alsaQueueInfoClass, "name=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_set_name), 1);
  rb_define_method(alsaQueueInfoClass, "owner=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_set_owner), 1);
  rb_define_method(alsaQueueInfoClass, "queue", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_get_queue), 0);
  rb_define_method(alsaQueueInfoClass, "name", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_get_name), 0);
  rb_define_method(alsaQueueInfoClass, "owner", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_get_owner), 0);
  rb_define_method(alsaQueueInfoClass, "locked?", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_get_locked), 0);
  rb_define_method(alsaQueueInfoClass, "flags", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_get_flags), 0);
  rb_define_method(alsaQueueInfoClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_copy_to), -1);

  rb_define_method(alsaQueueStatusClass, "queue", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_get_queue), 0);
  rb_define_method(alsaQueueStatusClass, "events", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_get_events), 0);
  rb_define_method(alsaQueueStatusClass, "tick_time", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_get_tick_time), 0);
  rb_define_method(alsaQueueStatusClass, "real_time", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_get_real_time), 0);
  rb_define_method(alsaQueueStatusClass, "status", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_get_status), 0);
  rb_define_method(alsaQueueStatusClass, "running?", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_get_status_ex), 0);
  rb_define_method(alsaQueueStatusClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_copy_to), -1);
}
