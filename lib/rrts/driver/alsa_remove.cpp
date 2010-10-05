
#pragma implementation
#include "alsa_remove.h"
#include "alsa_midi_client.h"

#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaRemoveEventsClass;

/** Document-method: RRTS::Driver::AlsaRemoveEvents_i#copy_to
call-seq: copy_to([dst = nil]) -> copy

copy one snd_seq_remove_events_t to another (+dst+), or if +dst+ is not given, it returns a clone.
*/
ALSA_MIDI_COPY_TO_TEMPLATE(remove_events, RemoveEvents)

/** call-seq: condition() -> int

Get the removal condition bits.
*/
static VALUE
wrap_snd_seq_remove_events_get_condition(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  return UINT2NUM(snd_seq_remove_events_get_condition(rmp));
}

/** call-seq:  queue() -> id

Get the queueid that serves as a removal condition (events with _this_ queue)
*/
static VALUE
wrap_snd_seq_remove_events_get_queue(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  return INT2NUM(snd_seq_remove_events_get_queue(rmp));
}

/** call-seq:  time_tick() -> int

Get the event timestamp (in ticks) as removal condition.
*/
static VALUE
ARE_get_time_tick(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  return UINT2NUM(snd_seq_remove_events_get_time(rmp)->tick);
}

/** call-seq: time_real() -> [sec, nsec]

Get the event timestamp as removal condition
*/
static VALUE
ARE_get_time_real(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  const snd_seq_timestamp_t * const tm = snd_seq_remove_events_get_time(rmp);
  return rb_ary_new3(2, UINT2NUM(tm->time.tv_sec), UINT2NUM(tm->time.tv_nsec));
}

/** call-seq: dest() -> [clientid, portid]

Get the event destination address as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_get_dest(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  const snd_seq_addr_t* const a = snd_seq_remove_events_get_dest(rmp);
  return rb_ary_new3(2, UINT2NUM(a->client), UINT2NUM(a->port));
}

/** call-seq: channel() -> int

Get the event channel as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_get_channel(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  return INT2NUM(snd_seq_remove_events_get_channel(rmp));
}

/** call-seq: type() -> int

Get the event type as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_get_event_type(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  return INT2NUM(snd_seq_remove_events_get_event_type(rmp));
}

/** call-seq: tag() -> int

Get the event tag id as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_get_tag(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  return INT2NUM(snd_seq_remove_events_get_tag(rmp));
}

/** call-seq: condition = flags

Set the removal condition bits. These bits must be used in conjunction with other
arguments and specify which values are checked.

*IMPORTANT*: the other setters do *not* set implicit flags.


Parameters:
[flags]   a combination of:
          - +SND_SEQ_REMOVE_INPUT+, all input queues will be flushed (not a restriction)
          - +SND_SEQ_REMOVE_OUTPUT+, all output queues will be flushed ("")
          - +SND_SEQ_REMOVE_DEST+, 'with this destination', use +dest=+
          - +SND_SEQ_REMOVE_DEST_CHANNEL+
          - +SND_SEQ_REMOVE_TIME_BEFORE+
          - +SND_SEQ_REMOVE_TIME_AFTER+
          - +SND_SEQ_REMOVE_TIME_TICK+, to indicate time given is in ticks
          - +SND_SEQ_REMOVE_EVENT_TYPE+
          - +SND_SEQ_REMOVE_TAG_MATCH+, with identical tag.
          - +SND_SEQ_REMOVE_IGNORE_OFF+, do not flush any +OFF+ events (as in NOTE_OFF etc.)
            Because that could make things worse.
*/
static VALUE
wrap_snd_seq_remove_events_set_condition(VALUE v_rmp, VALUE v_flags)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  snd_seq_remove_events_set_condition(rmp, NUM2UINT(v_flags));
  return Qnil;
}

/** call-seq:  queue = queueid

Set the queue as removal condition. This can be used to remove events within that queue.

Parameters:
[queue]  either a queueid or a RRTS::MidiQueue

See RRTS::Driver::AlsaRemoveClass_i#condition=.
*/
static VALUE
wrap_snd_seq_remove_events_set_queue(VALUE v_rmp, VALUE v_queue)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  RRTS_DEREF_DIRTY(v_queue, @id);
  snd_seq_remove_events_set_queue(rmp, NUM2INT(v_queue));
  return Qnil;
}

/** call-seq:  time = time

Set the timestamp as removal condition.
Parameters:
[time]   an integer, for specifying ticks, or a tuple of splat of seconds and nanoseconds

Normally used with the flags +SND_SEQ_REMOVE_TIME_AFTER+ or +SND_SEQ_REMOVE_TIME_BEFORE+.

See RRTS::Driver::AlsaRemoveClass_i#condition=.

*/
static VALUE
wrap_snd_seq_remove_events_set_time(int argc, VALUE *argv, VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  VALUE v_sec, v_nsec;
  rb_scan_args(argc, argv, "11", &v_sec, &v_nsec);
  snd_seq_timestamp_t time;
  if (NIL_P(v_nsec))
    {
      if (FIXNUM_P(v_sec))
          time.tick = NUM2UINT(v_sec);
      else
        {
          v_sec = rb_check_array_type(v_sec);
          if (!RTEST(v_sec)) RAISE_MIDI_ERROR_FMT0("API call error: bad time format");
          time.time.tv_sec = NUM2UINT(rb_ary_entry(v_sec, 0));
          time.time.tv_nsec = NUM2UINT(rb_ary_entry(v_sec, 1));
        }
    }
  else
    {
      time.time.tv_sec = NUM2UINT(v_sec);
      time.time.tv_nsec = NUM2UINT(v_nsec);
    }
  snd_seq_remove_events_set_time(rmp, &time);
  return Qnil;
}

/** call-seq: time_real = sec, nsec

For removing events based on this specified realtime. It is also possible to pass a tuple
as single argument.

See RRTS::Driver::AlsaRemoveClass_i#condition=.
*/
static VALUE
ARE_set_time_real(int argc, VALUE *argv, VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  VALUE v_sec, v_nsec;
  rb_scan_args(argc, argv, "11", &v_sec, &v_nsec);
  if (NIL_P(v_nsec))
  {
    v_sec = rb_check_array_type(v_sec);
    if (!RTEST(v_sec)) RAISE_MIDI_ERROR_FMT0("API call error: realtime needs sec+nsec tuple");
    v_nsec = rb_ary_entry(v_sec, 1);
    v_sec = rb_ary_entry(v_sec, 0);
  }
  snd_seq_timestamp_t time;
  time.time.tv_sec = NUM2UINT(v_sec);
  time.time.tv_nsec = NUM2UINT(v_nsec);
  snd_seq_remove_events_set_time(rmp, &time);
  return Qnil;
}

/** call-seq: time = ticks

For removing events based on a tick time. Note that +SND_SEQ_REMOVE_TIME_TICK+
should be set to indicate the time is in fact in ticks (guess from Eugene).

See RRTS::Driver::AlsaRemoveClass_i#condition=.
*/
static VALUE
ARE_set_time_tick(VALUE v_rmp, VALUE v_ticks)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  snd_seq_timestamp_t time;
  time.tick = NUM2UINT(v_ticks);
  snd_seq_remove_events_set_time(rmp, &time);
  return Qnil;
}

/** call-seq: dest = addressspecification

Set the destination address as removal condition.
Parameters:
[dest]   a single RRTS::Driver::AlsaPortInfo_i or RRTS::MidiPort. Or a tuple [client, portid]
         where client can be RRTS::Driver::AlsaClientInfo_i or RRTS::MidiClient.

See RRTS::Driver::AlsaRemoveClass_i#condition=.
*/
static VALUE
wrap_snd_seq_remove_events_set_dest(int argc, VALUE *argv, VALUE v_rmp)
{
  FETCH_ADDRESSES();
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  snd_seq_addr_t a;
  a.client = NUM2INT(v_clientid);
  a.port = NUM2INT(v_portid);
  snd_seq_remove_events_set_dest(rmp, &a);
  return Qnil;
}

/** call-seq: channel = aChannel

Set the channel as removal condition.

See RRTS::Driver::AlsaRemoveClass_i#condition=.
*/
static VALUE
wrap_snd_seq_remove_events_set_channel(VALUE v_rmp, VALUE v_ch)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  snd_seq_remove_events_set_channel(rmp, NUM2INT(v_ch));
  return Qnil;
}

/** call-seq:  event_type = type

Set the event type as removal condition.

See RRTS::Driver::AlsaRemoveClass_i#condition=.
*/
static VALUE
wrap_snd_seq_remove_events_set_event_type(VALUE v_rmp, VALUE v_evtype)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  snd_seq_remove_events_set_event_type(rmp, NUM2INT(v_evtype));
  return Qnil;
}

/** call-seq:  tag = value

Set the event tag as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_set_tag(VALUE v_rmp, VALUE v_tag)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  snd_seq_remove_events_set_tag(rmp, NUM2INT(v_tag));
  return Qnil;
}

void
alsa_remove_init()
{
  //arg1 for snd_seq_ev_is....type
  WRAP_CONSTANT(SND_SEQ_REMOVE_INPUT);
  WRAP_CONSTANT(SND_SEQ_REMOVE_OUTPUT);
  WRAP_CONSTANT(SND_SEQ_REMOVE_DEST);
  WRAP_CONSTANT(SND_SEQ_REMOVE_DEST_CHANNEL);
  WRAP_CONSTANT(SND_SEQ_REMOVE_TIME_BEFORE);
  WRAP_CONSTANT(SND_SEQ_REMOVE_TIME_AFTER);
  WRAP_CONSTANT(SND_SEQ_REMOVE_TIME_TICK);
  WRAP_CONSTANT(SND_SEQ_REMOVE_EVENT_TYPE);
  WRAP_CONSTANT(SND_SEQ_REMOVE_TAG_MATCH);
  WRAP_CONSTANT(SND_SEQ_REMOVE_IGNORE_OFF);

  /** Document-class: RRTS::Driver::AlsaRemoveClass_i

     Class to remove (already sent) events from queues and buffers.

     You don't want to use this class. Instead use RRTS::MidiQueue#clear.

  */

  alsaRemoveEventsClass = rb_define_class_under(alsaDriver, "AlsaRemoveEvents_i", rb_cObject);
  rb_define_method(alsaRemoveEventsClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_copy_to), -1);
  rb_define_method(alsaRemoveEventsClass, "condition",
                   RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_condition), 0);
  rb_define_method(alsaRemoveEventsClass, "queue",
                   RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_queue), 0);
  rb_define_method(alsaRemoveEventsClass, "time_tick",
                                    RUBY_METHOD_FUNC(ARE_get_time_tick), 0);
  rb_define_method(alsaRemoveEventsClass, "time_real", RUBY_METHOD_FUNC(ARE_get_time_real), 0);
  rb_define_method(alsaRemoveEventsClass, "dest", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_dest), 0);
  rb_define_method(alsaRemoveEventsClass, "channel", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_channel), 0);
  rb_define_method(alsaRemoveEventsClass, "event_type", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_event_type), 0);
  rb_define_method(alsaRemoveEventsClass, "type", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_event_type), 0);
  rb_define_method(alsaRemoveEventsClass, "tag", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_tag), 0);
  rb_define_method(alsaRemoveEventsClass, "condition=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_condition), 1);
  rb_define_method(alsaRemoveEventsClass, "queue=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_queue), 1);
  rb_define_method(alsaRemoveEventsClass, "time=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_time), -1);
  rb_define_method(alsaRemoveEventsClass, "time_real=", RUBY_METHOD_FUNC(ARE_set_time_real), -1);
  rb_define_method(alsaRemoveEventsClass, "time_tick=", RUBY_METHOD_FUNC(ARE_set_time_tick), 1);
  rb_define_method(alsaRemoveEventsClass, "dest=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_dest), -1);
  rb_define_method(alsaRemoveEventsClass, "channel=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_channel), 1);
  rb_define_method(alsaRemoveEventsClass, "type=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_event_type), 1);
  rb_define_method(alsaRemoveEventsClass, "event_type=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_event_type), 1);
  rb_define_method(alsaRemoveEventsClass, "tag=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_tag), 1);


}