
// #define DUMP_API

#pragma implementation
#include "alsa_midi_event.h"
#include "alsa_midi.h"
#include "alsa_midi_queue.h"
#include "alsa_midi_client.h"

#if defined(DUMP_API)
#define DUMP_STREAM stderr
#endif

#include <ruby/dl.h>
#include <alsa/asoundlib.h>
#include <math.h> // floor

//  DOC on all events + types http://alsa-project.org/alsa-doc/alsa-lib/group___seq_events.html

VALUE alsaMidiEventClass;

const char *
dump_event(snd_seq_event_t *ev, const char *file, int line)
{
  char *const result = ALLOC_N(char, 2048); // well, this is for debugging purposes. Although
  char *s = result;
  // some types: NoTE == 5. NOTEON == 6 NOTEOFF = 7
  // CONTROLLER = 10, PGMCHANGE = 11
  // TEMPO = 35
  // SYSEX = 130
  if (file)
    s += sprintf(s, "DUMP(ev, %s:%d)->{type:%d, flags:%d, tag:%d, queue:%d\n", file, line,
                 ev->type, ev->flags, ev->tag, ev->queue);
  else
    s += sprintf(s, "Event{type:%d, flags:%d, tag:%d, queue:%d\n", ev->type, ev->flags, ev->tag, ev->queue);
  if (snd_seq_ev_is_real(ev))
    s += sprintf(s, "\ttime: %d seconds, %d nanoseconds\n", ev->time.time.tv_sec,
                    ev->time.time.tv_nsec);
  else
    s += sprintf(s, "\ttime: %d ticks\n", ev->time.tick);
  s += sprintf(s, "\tfrom %d:%d  to  %d:%d\n", ev->source.client, ev->source.port,
                  ev->dest.client, ev->dest.port);
  if (snd_seq_ev_is_note_type(ev))
    {
      s += sprintf(s, "\tchannel: %d, note: %d, vel: %d, duration: %d, off_vel: %d\n",
                      ev->data.note.channel, ev->data.note.note, ev->data.note.velocity,
                      ev->data.note.duration, ev->data.note.off_velocity);
    }
  else if (snd_seq_ev_is_control_type(ev))
    {
      switch (ev->type)
        {
        case SND_SEQ_EVENT_CONTROLLER:
          s += sprintf(s, "\tchannel: %d, param: %d, value: %d\n", ev->data.control.channel,
                          ev->data.control.param, ev->data.control.value);
          break;
        default:
          s += sprintf(s, "\tchannel: %d, value: %d\n", ev->data.control.channel,
                       ev->data.control.value);
          break;
        }
    }
  else if (snd_seq_ev_is_queue_type(ev))
    {
      s += sprintf(s, "\tqueue: %d", ev->data.queue.queue);
      switch (ev->type)
        {
        case SND_SEQ_EVENT_TEMPO:
          s += sprintf(s, ", TEMPO: %d", ev->data.queue.param.value);
          break;
        default:
          s += sprintf(s, "??");
        }
    }
  s += sprintf(s, "}\n");
  return result;
}

/* string inspect
for debugging purposes
*/
static VALUE
alsaMidiEventClass_inspect(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  const char *buf = dump_event(ev);
  VALUE r = rb_str_new2(buf);
  free((void *)buf);
  return r;
}

/* self clear
Initialize the event with all zeroes
*/
static VALUE
wrap_snd_seq_ev_clear(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_clear(%p)\n", ev);
#endif
  snd_seq_ev_clear(ev);
  return v_ev;
}

/* self set_noteon(channel, key, velocity)
Make the event a NOTEON event. Note that NOTEON events with velocity == 0 yield
as NOTEOFF events. Channels must be in range 0..15, keys and velocity in 0..127.
*/
static VALUE
wrap_snd_seq_ev_set_noteon(VALUE v_ev, VALUE v_ch, VALUE v_key, VALUE v_vel)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_set_noteon(%p, %d, %d, %d)\n", ev, NUM2INT(v_ch), NUM2INT(v_key), NUM2INT(v_vel));
#endif
  snd_seq_ev_set_noteon(ev, NUM2UINT(v_ch), NUM2UINT(v_key), NUM2UINT(v_vel));
  return v_ev;
}

/* self set_noteoff(channel, key [, off_velocity])
See #set_noteon.
*/
static VALUE
wrap_snd_seq_ev_set_noteoff(int argc, VALUE *argv, VALUE v_ev)
{
  VALUE v_ch, v_key, v_vel;
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  rb_scan_args(argc, argv, "21", &v_ch, &v_key, &v_vel);
  const uint vel = NIL_P(v_vel) ? 0 : NUM2UINT(v_vel);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_set_noteoff(%p, %d, %d, %d)\n", ev, NUM2INT(v_ch), NUM2INT(v_key), vel);
#endif
  snd_seq_ev_set_noteoff(ev, NUM2UINT(v_ch), NUM2UINT(v_key), vel);
  return v_ev;
}

/* self set_note(channel, key, velocity, duration)
Make it a note-event and set the 4 four parameters for such events. Note that NOTE
is not NOTEON.
See #set_noteon. Duration is given in ticks or milliseconds, depending on scheduling mode.
See also #schedule_real and #schedule_tick.

Note the NOTE events are not MIDI at all. Supposedly Alsa interprets these events when
put in a queue, and internally schedules the NOTEON and NOTEOFF events.
*/
static VALUE
wrap_snd_seq_ev_set_note(VALUE v_ev, VALUE v_ch, VALUE v_key, VALUE v_vel, VALUE v_dur)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_set_note(%p, %d, %d, %d, %d)\n", ev, NUM2INT(v_ch), NUM2INT(v_key), NUM2INT(v_vel), NUM2INT(v_dur));
#endif
  snd_seq_ev_set_note(ev, NUM2UINT(v_ch), NUM2UINT(v_key), NUM2UINT(v_vel), NUM2UINT(v_dur));
  return v_ev;
}

/* self set_keypress(channel, key, velocity)
Make this event an AFTERTOUCH event (aka KEYPRESS). See #noteon for valid ranges.
*/
static VALUE
wrap_snd_seq_ev_set_keypress(VALUE v_ev, VALUE v_ch, VALUE v_key, VALUE v_vel)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
 #if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_set_keypress(%p, %d, %d, %d)\n", ev, NUM2INT(v_ch), NUM2INT(v_key), NUM2INT(v_vel));
#endif
  snd_seq_ev_set_keypress(ev, NUM2UINT(v_ch), NUM2UINT(v_key), NUM2UINT(v_vel));
  return v_ev;
}

/* self set_pgmchange(channel, value)
Make the event a PGMCHANGE event with gaven voice number. This event is normally preceded by
a bank select event. Value should be in range 0..127.
*/
static VALUE
wrap_snd_seq_ev_set_pgmchange(VALUE v_ev, VALUE v_ch, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_set_pgmchange(%p, %d, %d)\n", ev, NUM2INT(v_ch), NUM2INT(v_val));
#endif
  snd_seq_ev_set_pgmchange(ev, NUM2UINT(v_ch), NUM2INT(v_val));
  return v_ev;
}

/* self set_pitchbend(channel, value)
Make the event a PITCHBEND event, value should be in the range -0x2000..+0x1FFF
(-8192..8191).
*/
static VALUE
wrap_snd_seq_ev_set_pitchbend(VALUE v_ev, VALUE v_ch, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_set_pitchbend(%p, %d, %d)\n", ev, NUM2INT(v_ch), NUM2INT(v_val));
#endif
  snd_seq_ev_set_pitchbend(ev, NUM2UINT(v_ch), NUM2INT(v_val));
  return v_ev;
}

/* self set_chanpress(channel, value)
Make the event a CHANPRESS (aftertouch on all playing notes). Value is in range 0..127
*/
static VALUE
wrap_snd_seq_ev_set_chanpress(VALUE v_ev, VALUE v_ch, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_set_chanpress(%p, %d, %d)\n", ev, NUM2INT(v_ch), NUM2INT(v_val));
#endif
  snd_seq_ev_set_chanpress(ev, NUM2UINT(v_ch), NUM2INT(v_val));
  return v_ev;
}

/* sysex=(data)
Make the event a sysex. The buffer given is copied internally somewhere. It should be
investigated how solid this is.
This is probably the same as #set_variable
*/
static VALUE
wrap_snd_seq_ev_set_sysex(VALUE v_ev, VALUE v_data)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  Check_Type(v_data, T_STRING);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_set_sysex(%p, %ld bytes)\n", ev, RSTRING_LEN(v_data));
#endif
  snd_seq_ev_set_sysex(ev, RSTRING_LEN(v_data), RSTRING_PTR(v_data));
  return Qnil;
}

/* self set_controller(channel, param, value)
Make it a CONTROLLER event. param and value are in range 0..127
Note that some controller events have a MSB and LSB counterpart so that the effective
range becomes 0..16383.
*/
static VALUE
wrap_snd_seq_ev_set_controller(VALUE v_ev, VALUE v_ch, VALUE v_cc, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_set_controller(%p, %d, %d, %d)\n", ev, NUM2INT(v_ch), NUM2INT(v_cc), NUM2INT(v_val));
#endif
  snd_seq_ev_set_controller(ev, NUM2UINT(v_ch), NUM2UINT(v_cc), NUM2INT(v_val));
  return v_ev;
}

/* self set_subs
sets the destination to 'SUBSCRIBERS:UNKNOWN', a special client+port
This causes the event to be broadcast to all subscribers of the connection.
For MidiEvent you can also say event.dest = sequencer.subscribers_unknown_port
which makes it more understandable
*/
static VALUE
wrap_snd_seq_ev_set_subs(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_set_subs(%p)\n", ev);
#endif
  snd_seq_ev_set_subs(ev);
  return v_ev;
}

/*  call-seq:
      schedule_tick(queue, relative?, tick) -> self

Sets the queue and the specified eventtime in the event. Queue can be an integer or MidiQueue
*/
static VALUE
wrap_snd_seq_ev_schedule_tick(VALUE v_ev, VALUE v_qid, VALUE v_relative, VALUE v_tick)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  RRTS_DEREF_DIRTY(v_qid, @id);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_schedule_tick(%p, %d, %s, %ud)\n", ev, NUM2INT(v_qid), BOOL2INT(v_relative) ? "true" : "false", NUM2UINT(v_tick));
#endif
  snd_seq_ev_schedule_tick(ev, NUM2INT(v_qid), BOOL2INT(v_relative), NUM2UINT(v_tick));
  return v_ev;
}

/* self schedule_real qid, relative, timetuple
Sets the queue and realtime for the event. The subscription must support this.
*/
static VALUE
wrap_snd_seq_ev_schedule_real(VALUE v_ev, VALUE v_qid, VALUE v_relative, VALUE v_time)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  VALUE v_timedbl = rb_check_float_type(v_time);
  snd_seq_real_time tm;
  if (RTEST(v_timedbl))
    {
      const double t = NUM2DBL(v_timedbl);
      const snd_seq_real_time ctm = { uint(t), uint((t - floor(t)) * 1000000000.0) };
      tm = ctm;
    }
  else
    {
      v_time = rb_check_array_type(v_time);
      if (!RTEST(v_time)) RAISE_MIDI_ERROR_FMT0("bad realtime for schedule_real");
      VALUE secs = rb_ary_entry(v_time, 0), nsecs = rb_ary_entry(v_time, 1);
      const snd_seq_real_time ctm = { NUM2UINT(secs), NUM2UINT(nsecs) };
      tm = ctm;
    }
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_schedule_real(%p, %d, %s, %ud-%ud)\n", ev, NUM2INT(v_qid), BOOL2INT(v_relative) ? "true" : "false", tm.tv_sec, tm.tv_nsec);
#endif
  snd_seq_ev_schedule_real(ev, NUM2INT(v_qid), BOOL2INT(v_relative), &tm);
  return v_ev;
}

/* :rdoc:
the following type checking methods exist:
  bool note_type?
  bool result_type?
  bool control_type?
  bool channel_type?
  bool message_type?
  bool subscribe_type?
  bool sample_type?
  bool user_type?
  bool instr_type?
  bool fixed_type?
  bool variable_type?
  bool varusr_type?
See alsa documentation, but that won't help you.
*/
#define IS_TYPE_EXPANSIONS \
IS_TYPE_EXPANSION(result) \
IS_TYPE_EXPANSION(note) \
IS_TYPE_EXPANSION(control) \
IS_TYPE_EXPANSION(channel) \
IS_TYPE_EXPANSION(message) \
IS_TYPE_EXPANSION(subscribe) \
IS_TYPE_EXPANSION(sample) \
IS_TYPE_EXPANSION(user) \
IS_TYPE_EXPANSION(instr) \
IS_TYPE_EXPANSION(fixed) \
IS_TYPE_EXPANSION(variable) \
IS_TYPE_EXPANSION(varusr) \

/*      NOT CONSECUTIVE...
int is 32 bits!!!!
class       event
result      SYSTEM              event:int, result:int
RESULT              ""
note        NoTE                channel: uc, note: uc, velocity: uc, off_vel:uc, duration:uint
NOTEON              channel: uc, note: uc, velocity: uc
NOTEOFF             ""
KEYPRESS            ""                      Aftertouch change.
ctrl        CONTROLLER          channel:uc, param: uint, value: int
PGMCHANGE           ""
CHANPRESS           ...
PITCHBEND
CONTROL14
NONREGPARAM
REGPARAM
SONGPOS
SONGSEL
QFRAME
TIMESIGN
KEYSIGN
queue_control            ALL :  queue: uc
0/1 FROM:  value: int, time: timestamp, pos:uint, skew: skew_t,
d32: uint[2],  d8: uc[8]
timestamp  =  tick: uint OR(!!) time: tv_sec: uint + tv_nsec: uint
skew =        value: uint, base: uint
START
STOP
CONTINUE
SETPOS_TICK         pos
SETPOS_TIME         time
TEMPO               value
CLOCK               NO DATA, 24 clocks are send per quarter note
TICK                NO DATA, 100 ticks are send each second (if send at all)
QUEUE_SKEW          skew
SYNC_POS            pos?
none        TUNE_REQUEST
RESET               reset machine request
SENSING             active sensing. Keepalive messages.
ECHO                echo back event (a ping?)
OSS                 OSS emu (???)
addr        CLIENT_START        client: uc,  port: uc
CLIENT_EXIT         ""
CLIENT_CHANGE       ...
PORT_START
PORT_EXIT
PORT_CHANGE
connect     PORT_SUBSCRIBED     sender, dest: snd_seq_addr_t, ie client,port:uc
PORT_UNSUBSCRIBED   ""
any         USR0 t/m USR9
ext         SYSEX
BOUNCE
USR_VAR0 t/m USR_VAR4
NOP         NONE

Structure of snd_seq_event_t
type: one of SYSTEM..NONE
flags, tag, queue: uc
time: timestamp as in queue control events
source, dest: as in connect events
data: ONE OF:
note: see above
ctrl:
raw8:             uc[12]
raw32:            uint[3]
ext:              len: uint (sz in bytes I guess), ptr to data
queue_control:
time
addr
connect
result

The ruby event class should therefor be as follows:
class BaseEvent
@flags, @tag, @queue
@time
if snd_seq_ev_is_abstime holds then in realtime?? (scheduled in absolute time)
def source: Port
def dest: Port
end

*/
#define IS_TYPE_EXPANSION(nam) \
static VALUE \
wrap_snd_seq_ev_is_##nam##_type(VALUE v_ev) \
{ \
snd_seq_event_t *ev; \
Data_Get_Struct(v_ev, snd_seq_event_t, ev); \
return INT2BOOL(snd_seq_ev_is_##nam##_type(ev)); \
}

IS_TYPE_EXPANSIONS
#undef IS_TYPE_EXPANSION

/* :rdoc:

The following methods exist:
   bool abstime?   , is the time absolute
   bool reltime?   , or relative
   bool direct?    , bypass buffers when sending
   bool reserved?  , stay off
   bool prior?     , is it a high-priority event
   bool fixed?     , message has fixed size
   bool variable?  , or variable
   bool tick?      , times are set in ticks (1 bar = 384 ticks)
   bool real?      , times are set in nanoseconds
*/

#define EV_IS_EXPANSIONS \
EV_IS_EXPANSION(abstime) \
EV_IS_EXPANSION(reltime) \
EV_IS_EXPANSION(direct) \
EV_IS_EXPANSION(reserved) \
EV_IS_EXPANSION(prior) \
EV_IS_EXPANSION(fixed) \
EV_IS_EXPANSION(variable) \
EV_IS_EXPANSION(tick) \
EV_IS_EXPANSION(real) \

#define EV_IS_EXPANSION(nam) \
static VALUE \
wrap_snd_seq_ev_is_##nam(VALUE v_ev) \
{ \
snd_seq_event_t *ev; \
Data_Get_Struct(v_ev, snd_seq_event_t, ev); \
return INT2BOOL(snd_seq_ev_is_##nam(ev)); \
}

EV_IS_EXPANSIONS
#undef EV_IS_EXPANSION

/* bool type_check(to_check)
+to_check+ must be one off SND_SEQ_EVFLG_RESULT..SND_SEQ_EVFLG_VARUSR.
Flags cannot be combined using '|'.
*/
static VALUE
wrap_snd_seq_type_check(VALUE v_ev, VALUE v_x)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  const int x = NUM2INT(v_x);
  if (x < 0 || x > SND_SEQ_EVFLG_VARUSR) return Qnil;
  return INT2BOOL(snd_seq_type_check(ev, x));
}

/* int length
calculates the (encoded) byte-stream size of the event

Returns:
the size of decoded bytes, ie. the number of bytes (including message formatting)
required in the buffer to send the event.

This is not the same as #len.
*/
static VALUE
wrap_snd_seq_event_length(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
// HAHAHA   fprintf(stderr, "snd_seq_event_length is prone to crashes!!!! Hold yer horses!\n");
  return INT2NUM(snd_seq_event_length(ev));
}

/* int note

Returns the note. If this is not a note-message it returns nil instead.
*/
static VALUE
alsaMidiEventClass_note(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_note_type(ev)) return Qnil;
  return UINT2NUM(ev->data.note.note);
}

/* note=(value)

Alter the note value. Consider using set_note/on/off instead.
*/
static VALUE
alsaMidiEventClass_set_note(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.note.note = NUM2UINT(v_val);
  return Qnil;
}

/* velocity=(value)
Alter the velocity value. Consider using set_note/on/off instead.
*/
static VALUE
alsaMidiEventClass_set_velocity(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.note.velocity = NUM2UINT(v_val);
  return Qnil;
}

/* off_velocity=(value)
Specific for NoteOff and Note events
*/
static VALUE
alsaMidiEventClass_set_off_velocity(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.note.off_velocity = NUM2UINT(v_val);
  return Qnil;
}

/* duration=(value)
Set the duration in ticks or milliseconds, depending on the scheduling mode
*/
static VALUE
alsaMidiEventClass_set_duration(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.note.duration = NUM2UINT(v_val);
  return Qnil;
}

/* int channel
Valid for both note- and controlmessages
*/
static VALUE
alsaMidiEventClass_channel(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (snd_seq_ev_is_note_type(ev))
    return UINT2NUM(ev->data.note.channel);
  if (snd_seq_ev_is_control_type(ev))
    return UINT2NUM(ev->data.control.channel);
//   RAISE_MIDI_ERROR_FMT1("ev %d has no channel", ev->type);
  return Qnil;
}

/* channel=(channel)
Valid for both note- and controlmessages, provided the type is set properly first!
*/
static VALUE
alsaMidiEventClass_set_channel(VALUE v_ev, VALUE v_ch)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (snd_seq_ev_is_note_type(ev))
    ev->data.note.channel = NUM2UINT(v_ch);
  else if (snd_seq_ev_is_control_type(ev))
    ev->data.control.channel = NUM2UINT(v_ch);
  else
    RAISE_MIDI_ERROR_FMT0("API call error: setting channel, but type is incorrect");
  return Qnil;
}

/* int queue
Returns the queue id, as set.
*/
static VALUE
alsaMidiEventClass_queue(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->queue);
}

/* queue=(queue)
+queue+ can be an integer or a MidiQueue instance
*/
static VALUE
alsaMidiEventClass_set_queue(VALUE v_ev, VALUE v_queue)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  RRTS_DEREF_DIRTY(v_queue, @id);
  ev->queue = NUM2INT(v_queue);
  return Qnil;
}

/* int queue_queue
Returns the queueid for a queue-event (not the senderqueue)
*/
static VALUE
alsaMidiEventClass_queue_queue(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return UINT2NUM(ev->data.queue.queue);
}

/* queue_queue=(queue)
+queue+ can be an integer or a MidiQueue. This sets the subject of a queue-event,
not the senderqueue.
*/
static VALUE
alsaMidiEventClass_set_queue_queue(VALUE v_ev, VALUE v_queue)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  RRTS_DEREF_DIRTY(v_queue, @id);
  ev->data.queue.queue = NUM2UINT(v_queue);
  return Qnil;
}

/* int flags
Returns the flags set.
*/
static VALUE
alsaMidiEventClass_flags(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return UINT2NUM(ev->flags);
}

/* flags=(int)
Alter the Alsa flags for the event
*/
static VALUE
alsaMidiEventClass_set_flags(VALUE v_ev, VALUE v_flags)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->flags = NUM2UINT(v_flags);
  return Qnil;
}

/* int param
Returns the controller param, or nil if this is not a controller event
*/
static VALUE
alsaMidiEventClass_param(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_control_type(ev)) return Qnil;
  return UINT2NUM(ev->data.control.param);
}

/* param=(value)
Changed the controller param
*/
static VALUE
alsaMidiEventClass_set_param(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.control.param = NUM2UINT(v_val);
  return Qnil;
}

/* int value
Returns the controller value, or nil, if this is not a controller event
*/
static VALUE
alsaMidiEventClass_value(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_control_type(ev)) return Qnil;
  return INT2NUM(ev->data.control.value);
}

/* value=(value)
Alters the controller value
*/
static VALUE
alsaMidiEventClass_set_value(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.control.value = NUM2INT(v_val);
  return Qnil;
}

/* string sysex
Returns the sysex value as a bytesstring (encoding ascii-8bits).
Returns nil if the event is not of the _variable_ type, which hopefully
is the same a 'sysex'.
*/
static VALUE
alsaMidiEventClass_sysex(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_variable_type(ev)) return Qnil; // ???
  const uint len = ev->data.ext.len;
  return rb_str_new((const char *)ev->data.ext.ptr, len);
}

/* int velocity
Returns the velocity, or nil if this is not a note type event
*/
static VALUE
alsaMidiEventClass_velocity(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_note_type(ev)) return Qnil;
  return INT2NUM(ev->data.note.velocity);
}

/* int type
Returns the alsa type of the event. Will be one of the SND_SEQ_EVENT_... constants
*/
static VALUE
alsaMidiEventClass_type(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->type);
}

/* type=(value)
Alters the type of the event
*/
static VALUE
alsaMidiEventClass_set_type(VALUE v_ev, VALUE v_tp)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->type = NUM2INT(v_tp);
  return Qnil;
}

/* int len

Better use sysex.length.
Also do not confuse with length.
Returns nil if this is not a _variable_ type event.
*/
static VALUE
alsaMidiEventClass_len(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_variable_type(ev)) return Qnil; // ???
  return UINT2NUM(ev->data.ext.len);
}

/* int off_velocity
Returns the off_velocity for NOTE and NOTEOFF. Returns nil if not a note-event
*/
static VALUE
alsaMidiEventClass_off_velocity(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_note_type(ev)) return Qnil;
  return INT2NUM(ev->data.note.off_velocity);
}

/* int duration
For none note-events returns nil.
*/
static VALUE
alsaMidiEventClass_duration(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_note_type(ev)) return Qnil;
  return INT2NUM(ev->data.note.duration);
}

/* client, port dest
Returns a tuple of two integers
*/
static VALUE
alsaMidiEventClass_dest(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return rb_ary_new3(2, INT2NUM(ev->dest.client), INT2NUM(ev->dest.port));
}

/* int dest_port
Returns the destination portid
*/
static VALUE
alsaMidiEventClass_dest_port(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->dest.port);
}

/* int dest_client
Returns the destinations clientid
*/
static VALUE
alsaMidiEventClass_dest_client(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->dest.client);
}

/* client, port source
Returns the source as a tuple clientid + portid
*/
static VALUE
alsaMidiEventClass_source(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return rb_ary_new3(2, INT2NUM(ev->source.client), INT2NUM(ev->source.port));
}

/* int source_port
See also #source
*/
static VALUE
alsaMidiEventClass_source_port(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->source.port);
}

/* int source_client
See also #source
*/
static VALUE
alsaMidiEventClass_source_client(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->source.client);
}

/* source=(address_specification)

 IMPORTANT: this differs from the alsa API which suffers from a naming inconsistency.
 You must pass a tuple clientid, portid or a MidiClient, portid tuple, or a single MidiPort instance.
 Examples:
     event.source = 20, 1
     event.source = [20, 1]
     event.source = myclient, 1
     event.source = source_port
*/
static VALUE
alsaMidiEventClass_set_source(int argc, VALUE *argv, VALUE v_ev)
{
  FETCH_ADDRESSES();
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->source.client = NUM2INT(v_clientid);
  ev->source.port = NUM2INT(v_portid);
  return Qnil;
}

/* source_client=(client)
The +client+ can be an integer (clientid) or a MidiClient instance
*/
static VALUE
alsaMidiEventClass_set_source_client(VALUE v_ev, VALUE v_clientid)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->source.client = NUM2INT(v_clientid);
  return Qnil;
}

/* source_port=(port)
This sets the port part of the source. This would be weird.
*/
static VALUE
alsaMidiEventClass_set_source_port(VALUE v_ev, VALUE v_portid)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  RRTS_DEREF_DIRTY(v_portid, @port);
  ev->source.port = NUM2INT(v_portid);
  return Qnil;
}

/* skewvalue, base queue_skew
Returns the queue skew as a tuple value + base
I have no idea what a queue skew is at this point. See Alsa docs (but they won't tell you)
*/
static VALUE
alsaMidiEventClass_queue_skew(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return rb_ary_new3(2, UINT2NUM(ev->data.queue.param.skew.value), UINT2NUM(ev->data.queue.param.skew.base));
}

/* queue_skew=(value, base)
You can also pass a tuple, as returned by #queue_skew for instance.
*/
static VALUE
alsaMidiEventClass_set_queue_skew(int argc, VALUE *argv, VALUE v_ev)
{
  VALUE v_val, v_base;
  rb_scan_args(argc, argv, "11", &v_val, &v_base);
  if (NIL_P(v_base))
    {
      v_val = rb_check_array_type(v_val);
      if (!RTEST(v_val)) RAISE_MIDI_ERROR_FMT0("API call error: skew needs value + base tuple");
      v_base = rb_ary_entry(v_val, 1);
      v_val = rb_ary_entry(v_val, 0);
    }
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.queue.param.skew.value = NUM2UINT(v_val);
  ev->data.queue.param.skew.base = NUM2UINT(v_base);
  return Qnil;
}

/* time=(time_specification)
If time is given as a single integer, it is ticks. Otherwise it must be two arguments
or a tuple, namely the seconds, and then the nanoseconds.

This does not change the scheduling mode. It just fills the time data structure.
*/
static VALUE
alsaMidiEventClass_set_time(int argc, VALUE *argv, VALUE v_ev)
{
  VALUE v_sec, v_nsec;
  rb_scan_args(argc, argv, "11", &v_sec, &v_nsec);
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (NIL_P(v_nsec))
    {
      if (FIXNUM_P(v_sec))
        {
          ev->time.tick = NUM2UINT(v_sec);
          return Qnil;
        }
      VALUE v_secdbl = rb_check_float_type(v_sec);
      if (RTEST(v_secdbl))
        {
          const double t = NUM2DBL(v_secdbl);
          ev->time.time.tv_sec = uint(t);
          ev->time.time.tv_nsec = uint((t - floor(t)) * 1000000000.0);
          return Qnil;
        }
      v_sec = rb_check_array_type(v_sec);
      if (!RTEST(v_sec)) RAISE_MIDI_ERROR_FMT0("API call error: bad time format");
      v_nsec = rb_ary_entry(v_sec, 1);
      v_sec = rb_ary_entry(v_sec, 0);
    }
  ev->time.time.tv_sec = NUM2UINT(v_sec);
  ev->time.time.tv_nsec = NUM2UINT(v_nsec);
  return Qnil;
}

/* float time_real
Returns a realtime tuple: seconds + nanoseconds
*/
static VALUE
alsaMidiEventClass_time_real(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return DBL2NUM(double(ev->time.time.tv_sec) + 1000000000.0 * ev->time.time.tv_nsec);
}

/* call-seq:
    time_real=(sec, nsec)
    time_real=float

See #time=
*/
static VALUE
alsaMidiEventClass_set_time_real(int argc, VALUE *argv, VALUE v_ev)
{
  VALUE v_sec, v_nsec;
  rb_scan_args(argc, argv, "11", &v_sec, &v_nsec);
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (NIL_P(v_nsec))
  {
    VALUE v_secdbl = rb_check_float_type(v_sec);
    if (RTEST(v_secdbl))
      {
        const double t = NUM2DBL(v_secdbl);
        ev->time.time.tv_sec = uint(t);
        ev->time.time.tv_nsec = uint((t - floor(t)) * 1000000000.0);
        return Qnil;
      }
    v_sec = rb_check_array_type(v_sec);
    if (!RTEST(v_sec)) RAISE_MIDI_ERROR_FMT0("API call error: realtime needs sec+nsec tuple");
    v_nsec = rb_ary_entry(v_sec, 1);
    v_sec = rb_ary_entry(v_sec, 0);
  }
  ev->time.time.tv_sec = NUM2UINT(v_sec);
  ev->time.time.tv_nsec = NUM2UINT(v_nsec);
  return Qnil;
}

/* queue_time=(time_specification)
See also #time=, this works the same but for the timespecification within the queue-control
event
*/
static VALUE
alsaMidiEventClass_set_queue_time(int argc, VALUE *argv, VALUE v_ev)
{
  VALUE v_sec, v_nsec;
  rb_scan_args(argc, argv, "11", &v_sec, &v_nsec);
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (NIL_P(v_nsec))
    {
      if (FIXNUM_P(v_sec))
        {
          ev->data.queue.param.time.tick = NUM2UINT(v_sec);
          return Qnil;
        }
      VALUE v_secdbl = rb_check_float_type(v_sec);
      if (RTEST(v_secdbl))
        {
          const double t = NUM2DBL(v_secdbl);
          ev->data.queue.param.time.time.tv_sec = uint(t);
          ev->data.queue.param.time.time.tv_nsec = uint((t - floor(t)) * 1000000000.0);
          return Qnil;
        }
      v_sec = rb_check_array_type(v_sec);
      if (!RTEST(v_sec)) RAISE_MIDI_ERROR_FMT0("API call error: bad time format");
      v_nsec = rb_ary_entry(v_sec, 1);
      v_sec = rb_ary_entry(v_sec, 0);
    }
  ev->data.queue.param.time.time.tv_sec = NUM2UINT(v_sec);
  ev->data.queue.param.time.time.tv_nsec = NUM2UINT(v_nsec);
  return Qnil;
}

/* call-seq:
    float queue_time_real
Returns the set realtime for a queue-control event
*/
static VALUE
alsaMidiEventClass_queue_time_real(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return DBL2NUM(double(ev->data.queue.param.time.time.tv_sec)
                 + 1000000000.0 * ev->data.queue.param.time.time.tv_nsec);
}

/* call-seq:
    queue_time_real=(sec, nsec)
    queue_time_real = float

Works in the same way as #time_real=, see also #queue_time=
*/
static VALUE
alsaMidiEventClass_set_queue_time_real(int argc, VALUE *argv, VALUE v_ev)
{
  VALUE v_sec, v_nsec;
  rb_scan_args(argc, argv, "11", &v_sec, &v_nsec);
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (NIL_P(v_nsec))
    {
      VALUE v_secdbl = rb_check_float_type(v_sec);
      if (RTEST(v_secdbl))
        {
          const double t = NUM2DBL(v_secdbl);
          ev->data.queue.param.time.time.tv_sec = uint(t);
          ev->data.queue.param.time.time.tv_nsec = uint((t - floor(t)) * 1000000000.0);
          return Qnil;
        }
      v_sec = rb_check_array_type(v_sec);
      if (!RTEST(v_sec)) RAISE_MIDI_ERROR_FMT0("API call error: realtime needs sec+nsec tuple");
      v_nsec = rb_ary_entry(v_sec, 1);
      v_sec = rb_ary_entry(v_sec, 0);
    }
  ev->data.queue.param.time.time.tv_sec = NUM2UINT(v_sec);
  ev->data.queue.param.time.time.tv_nsec = NUM2UINT(v_nsec);
  return Qnil;
}

/* dest=(address)
Sets the destination in the same way as #source= does
*/
static VALUE
alsaMidiEventClass_set_dest(int argc, VALUE *argv, VALUE v_ev)
{
  FETCH_ADDRESSES();
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->dest.client = NUM2INT(v_clientid);
  ev->dest.port = NUM2INT(v_portid);
  return Qnil;
}

/* dest_client=(client)
See #dest=
*/
static VALUE
alsaMidiEventClass_set_dest_client(VALUE v_ev, VALUE v_clientid)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->dest.client = NUM2INT(v_clientid);
  return Qnil;
}

/* dest_port=(port)
See #dest=
*/
static VALUE
alsaMidiEventClass_set_dest_port(VALUE v_ev, VALUE v_portid)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->dest.port = NUM2INT(v_portid);
  return Qnil;
}

/* call-seq:
    time -> float
    time -> int
Returns either the realtime (as a float, or the ticks)
*/
static VALUE
alsaMidiEventClass_time(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  //   fprintf(stderr, __FILE__ ":%d: ev->time.tick=%ud, ev->time.time.tv_sec=%ud,nsec=%ud\n", __LINE__, ev->time.tick, ev->time.time.tv_sec, ev->time.time.tv_nsec);
  snd_seq_timestamp_t t = ev->time;
  const bool real = snd_seq_ev_is_real(ev);
  return real ? DBL2NUM(double(t.time.tv_sec) + double(t.time.tv_nsec) / 1000000000.0)
              : UINT2NUM(t.tick);
}

/* int time_tick
See also #time. If the event is a realtime event it will return nil.
*/
static VALUE
alsaMidiEventClass_time_tick(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_tick(ev)) return Qnil;
  return UINT2NUM(ev->time.tick);
}

/* time_tick=(value)
Sets the time in ticks, but does not change the timemode of the event
*/
static VALUE
alsaMidiEventClass_set_time_tick(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->time.tick = NUM2UINT(v_val);
  return Qnil;
}

/* int queue_value
Note that #value only works for CONTROLLER events. This method returns the
value of a queue parameter of a queue-control-event
*/
static VALUE
alsaMidiEventClass_queue_value(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->data.queue.param.value);
}

/* queue_value=(value)
Sets the value of a queue-control parameter
*/
static VALUE
alsaMidiEventClass_set_queue_value(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.queue.param.value = NUM2INT(v_val);
  return Qnil;
}

/* call-seq:
      queue_time -> float
      queue_time -> int
snd_seq_ev_is_real is used to decide whether ticks are returned or
a realtime (as a float)
*/
static VALUE
alsaMidiEventClass_queue_time(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  const snd_seq_timestamp_t &t = ev->data.queue.param.time;
  const bool real = snd_seq_ev_is_real(ev);
  return real ? DBL2NUM(double(t.time.tv_sec) + double(t.time.tv_nsec) / 1000000000.0)
              : UINT2NUM(t.tick);
}

/* call-seq:
    queue_time_tick -> int
Returns the queue time in ticks for a queue-control-message.
If the event was realtime it returns nil instead
*/
static VALUE
alsaMidiEventClass_queue_time_tick(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_tick(ev)) return Qnil;
  return UINT2NUM(ev->data.queue.param.time.tick);
}

/* call-seq:
      queue_time_tick= int
See #queue_time=
*/
static VALUE
alsaMidiEventClass_set_queue_time_tick(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.queue.param.time.tick = NUM2UINT(v_val);
  return Qnil;
}

/* call-seq:
      queue_position -> int
Returns the position parameter for a queue-control message
*/
static VALUE
alsaMidiEventClass_queue_position(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return UINT2NUM(ev->data.queue.param.position);
}

/* call-seq:
    queue_position= int
Alter the position. Do not confuse with queue_pos.
What is this anyway?
*/
static VALUE
alsaMidiEventClass_set_queue_position(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.queue.param.position = NUM2UINT(v_val);
  return Qnil;
}

/* tag=(value)
Tag can be in range of 0..255. I believe this can be used by the user to mark
specific events, so they can be removed using the tagvalue.
*/
static VALUE
wrap_snd_seq_ev_set_tag(VALUE v_ev, VALUE v_tag)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_tag(ev, NUM2UINT(v_tag));
  return Qnil;
}

/* self set_broadcast
Specify that the event must be broadcast to ALL clients on the system
*/
static VALUE
wrap_snd_seq_ev_set_broadcast(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_broadcast(ev);
  return v_ev;
}

/* self set_direct
Specify that the event does not use a queue and is send immediately.
If neither a schedule is perfomed, and 'direct' is not set, then the event
is still buffered and will only be send on a flush
*/
static VALUE
wrap_snd_seq_ev_set_direct(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_direct(ev);
  return v_ev;
}

/* priority=(bool)
specify that the event has a high priority (true) or normal (false)
*/
static VALUE
wrap_snd_seq_ev_set_priority(VALUE v_ev, VALUE v_prio)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_priority(ev, NUM2INT(v_prio));
  return Qnil;
}

/* self set_fixed
specify that the event has a fixed length
*/
static VALUE
wrap_snd_seq_ev_set_fixed(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_fixed(ev);
  return v_ev;
}

/* self set_variable(data)
Set variable data, making it a sysex. Probably the same as #sysex=
*/
static VALUE
wrap_snd_seq_ev_set_variable(VALUE v_ev, VALUE v_data)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  Check_Type(v_data, T_STRING);
  snd_seq_ev_set_variable(ev, RSTRING_LEN(v_data), RSTRING_PTR(v_data));
  return v_ev;
}

/* self set_varusr(data)
set a varusr event's data, making it a VARUSR event
*/
static VALUE
wrap_snd_seq_ev_set_varusr(VALUE v_ev, VALUE v_data)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  Check_Type(v_data, T_STRING);
  snd_seq_ev_set_varusr(ev, RSTRING_LEN(v_data), RSTRING_PTR(v_data));
  return v_ev;
}

/* self set_queue_control(type, queue, value)
Utility 'macro' for the other queue_control macro's
*/
static VALUE
wrap_snd_seq_ev_set_queue_control(VALUE v_ev, VALUE v_tp, VALUE v_q, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_queue_control(ev, NUM2INT(v_tp), NUM2UINT(v_q), NUM2INT(v_val));
  return v_ev;
}

/* self set_queue_start(queue)
make it a start queue event
*/
static VALUE
wrap_snd_seq_ev_set_queue_start(VALUE v_ev, VALUE v_q)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  RRTS_DEREF_DIRTY(v_q, @id);
  snd_seq_ev_set_queue_start(ev, NUM2UINT(v_q));
  return v_ev;
}

/* self set_queue_stop(queue)
make it a stop queue event
*/
static VALUE
wrap_snd_seq_ev_set_queue_stop(VALUE v_ev, VALUE v_q)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  RRTS_DEREF_DIRTY(v_q, @id);
  snd_seq_ev_set_queue_stop(ev, NUM2UINT(v_q));
  return v_ev;
}

/* self set_queue_continue(queue)
make it a queue continue event
*/
static VALUE
wrap_snd_seq_ev_set_queue_continue(VALUE v_ev, VALUE v_q)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  RRTS_DEREF_DIRTY(v_q, @id);
  snd_seq_ev_set_queue_continue(ev, NUM2UINT(v_q));
  return v_ev;
}

/* self set_queue_tempo(queue, tempo)
make it a set-queue-tempo event.
For the tempo parameter see Alsa docs (but there isn't any)
Use google to find meaningfull example.
*/
static VALUE
wrap_snd_seq_ev_set_queue_tempo(VALUE v_ev, VALUE v_q, VALUE v_tempo)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  RRTS_DEREF_DIRTY(v_q, @id);
  RRTS_DEREF(v_tempo, usecs_per_beat); // apply this, if existing
  snd_seq_ev_set_queue_tempo(ev, NUM2UINT(v_q), NUM2UINT(v_tempo));
  return v_ev;
}

/* call-seq:
    set_queue_pos_real(queue, [sec, nsec]) -> self
    set_queue_pos_real(queue, float) -> self
Make it a a realtime seek event, for changing the current position in queue.
Events are hence skipped or resend
*/
static VALUE
wrap_snd_seq_ev_set_queue_pos_real(VALUE v_ev, VALUE v_q, VALUE v_time)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  VALUE v_timedbl = rb_check_float_type(v_time);
  snd_seq_real_time tm;
  if (RTEST(v_timedbl))
    {
      const double t = NUM2DBL(v_timedbl);
      const snd_seq_real_time ctm = { uint(t), uint((t - floor(t)) * 1000000000.0) };
      tm = ctm;
    }
  else
    {
      v_time = rb_check_array_type(v_time);
      if (!RTEST(v_time)) RAISE_MIDI_ERROR_FMT0("bad realtime for queuepos_real");
      VALUE secs = rb_ary_entry(v_time, 0), nsecs = rb_ary_entry(v_time, 1);
      const snd_seq_real_time ctm = { NUM2UINT(secs), NUM2UINT(nsecs) };
      tm = ctm;
    }
  RRTS_DEREF_DIRTY(v_q, @id);
  snd_seq_ev_set_queue_pos_real(ev, NUM2UINT(v_q), &tm);
  return v_ev;
}

/* call-seq:
    set_queue_pos_tick(queue, int) -> self
See #set_queue_pos_real
*/
static VALUE
wrap_snd_seq_ev_set_queue_pos_tick(VALUE v_ev, VALUE v_q, VALUE v_ticks)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  RRTS_DEREF_DIRTY(v_q, @id);
  snd_seq_ev_set_queue_pos_tick(ev, NUM2UINT(v_q), NUM2UINT(v_ticks));
  return v_ev;
}

/* AlsaMidiEvent_i is the class wrapper for snd_seq_event_t.

Use this for one on one ports only as the ruby implementation has a lot
of overhead over the original one. Use MidiEvent if possible.
*/
void
alsa_midi_event_init()
{
  alsaMidiEventClass = rb_define_class_under(alsaDriver, "AlsaMidiEvent_i", rb_cObject);

  //arg1 for snd_seq_ev_is....type
  WRAP_CONSTANT(SND_SEQ_EVFLG_RESULT);
  WRAP_CONSTANT(SND_SEQ_EVFLG_NOTE);
  WRAP_CONSTANT(SND_SEQ_EVFLG_CONTROL);
  WRAP_CONSTANT(SND_SEQ_EVFLG_QUEUE);
  WRAP_CONSTANT(SND_SEQ_EVFLG_SYSTEM);
  WRAP_CONSTANT(SND_SEQ_EVFLG_MESSAGE);
  WRAP_CONSTANT(SND_SEQ_EVFLG_CONNECTION);
  WRAP_CONSTANT(SND_SEQ_EVFLG_SAMPLE);
  WRAP_CONSTANT(SND_SEQ_EVFLG_USERS);
  WRAP_CONSTANT(SND_SEQ_EVFLG_INSTR);
  WRAP_CONSTANT(SND_SEQ_EVFLG_QUOTE);
  WRAP_CONSTANT(SND_SEQ_EVFLG_NONE);
  WRAP_CONSTANT(SND_SEQ_EVFLG_RAW);
  WRAP_CONSTANT(SND_SEQ_EVFLG_FIXED);
  WRAP_CONSTANT(SND_SEQ_EVFLG_VARIABLE);
  WRAP_CONSTANT(SND_SEQ_EVFLG_VARUSR);

  // types:
  WRAP_CONSTANT(SND_SEQ_EVENT_SYSTEM);
  WRAP_CONSTANT(SND_SEQ_EVENT_RESULT);
  WRAP_CONSTANT(SND_SEQ_EVENT_NOTE);
  WRAP_CONSTANT(SND_SEQ_EVENT_NOTEON);
  WRAP_CONSTANT(SND_SEQ_EVENT_NOTEOFF);
  WRAP_CONSTANT(SND_SEQ_EVENT_KEYPRESS);
  WRAP_CONSTANT(SND_SEQ_EVENT_CONTROLLER);
  WRAP_CONSTANT(SND_SEQ_EVENT_PGMCHANGE);
  WRAP_CONSTANT(SND_SEQ_EVENT_CHANPRESS);
  WRAP_CONSTANT(SND_SEQ_EVENT_PITCHBEND);
  WRAP_CONSTANT(SND_SEQ_EVENT_CONTROL14);
  WRAP_CONSTANT(SND_SEQ_EVENT_NONREGPARAM);
  WRAP_CONSTANT(SND_SEQ_EVENT_REGPARAM);
  WRAP_CONSTANT(SND_SEQ_EVENT_SONGPOS);
  WRAP_CONSTANT(SND_SEQ_EVENT_SONGSEL);
  WRAP_CONSTANT(SND_SEQ_EVENT_START);
  WRAP_CONSTANT(SND_SEQ_EVENT_CONTINUE);
  WRAP_CONSTANT(SND_SEQ_EVENT_STOP);
  WRAP_CONSTANT(SND_SEQ_EVENT_SETPOS_TICK);
  WRAP_CONSTANT(SND_SEQ_EVENT_SETPOS_TIME);
  WRAP_CONSTANT(SND_SEQ_EVENT_TEMPO);
  WRAP_CONSTANT(SND_SEQ_EVENT_CLOCK);
  WRAP_CONSTANT(SND_SEQ_EVENT_TICK);
  WRAP_CONSTANT(SND_SEQ_EVENT_QUEUE_SKEW);
  WRAP_CONSTANT(SND_SEQ_EVENT_SYNC_POS);
  WRAP_CONSTANT(SND_SEQ_EVENT_TUNE_REQUEST);
  WRAP_CONSTANT(SND_SEQ_EVENT_RESET);
  WRAP_CONSTANT(SND_SEQ_EVENT_SENSING);
  WRAP_CONSTANT(SND_SEQ_EVENT_ECHO);
  WRAP_CONSTANT(SND_SEQ_EVENT_OSS);
  WRAP_CONSTANT(SND_SEQ_EVENT_CLIENT_START);
  WRAP_CONSTANT(SND_SEQ_EVENT_CLIENT_EXIT);
  WRAP_CONSTANT(SND_SEQ_EVENT_CLIENT_CHANGE);
  WRAP_CONSTANT(SND_SEQ_EVENT_PORT_START);
  WRAP_CONSTANT(SND_SEQ_EVENT_PORT_EXIT);
  WRAP_CONSTANT(SND_SEQ_EVENT_PORT_CHANGE);
  WRAP_CONSTANT(SND_SEQ_EVENT_PORT_SUBSCRIBED);
  WRAP_CONSTANT(SND_SEQ_EVENT_PORT_UNSUBSCRIBED);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR0);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR1);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR2);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR3);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR4);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR5);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR6);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR7);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR8);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR9);
  WRAP_CONSTANT(SND_SEQ_EVENT_SYSEX);
  WRAP_CONSTANT(SND_SEQ_EVENT_BOUNCE);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR_VAR0);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR_VAR1);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR_VAR2);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR_VAR3);
  WRAP_CONSTANT(SND_SEQ_EVENT_USR_VAR4);
  WRAP_CONSTANT(SND_SEQ_EVENT_NONE);

  // actual status bytes
  WRAP_CONSTANT(MIDI_CMD_NOTE_OFF);
  WRAP_CONSTANT(MIDI_CMD_NOTE_ON);
  WRAP_CONSTANT(MIDI_CMD_NOTE_PRESSURE);
  WRAP_CONSTANT(MIDI_CMD_CONTROL);
  WRAP_CONSTANT(MIDI_CMD_PGM_CHANGE);
  WRAP_CONSTANT(MIDI_CMD_CHANNEL_PRESSURE);
  WRAP_CONSTANT(MIDI_CMD_BENDER);
  WRAP_CONSTANT(MIDI_CMD_COMMON_SYSEX);
  WRAP_CONSTANT(MIDI_CMD_COMMON_MTC_QUARTER);
  WRAP_CONSTANT(MIDI_CMD_COMMON_SONG_POS);
  WRAP_CONSTANT(MIDI_CMD_COMMON_SONG_SELECT);
  WRAP_CONSTANT(MIDI_CMD_COMMON_TUNE_REQUEST);
  WRAP_CONSTANT(MIDI_CMD_COMMON_SYSEX_END);
  WRAP_CONSTANT(MIDI_CMD_COMMON_CLOCK);
  WRAP_CONSTANT(MIDI_CMD_COMMON_START);
  WRAP_CONSTANT(MIDI_CMD_COMMON_CONTINUE);
  WRAP_CONSTANT(MIDI_CMD_COMMON_STOP);
  WRAP_CONSTANT(MIDI_CMD_COMMON_SENSING);
  WRAP_CONSTANT(MIDI_CMD_COMMON_RESET);

  WRAP_CONSTANT(SND_SEQ_TIME_STAMP_TICK);
  WRAP_CONSTANT(SND_SEQ_TIME_STAMP_REAL);
  WRAP_CONSTANT(SND_SEQ_TIME_STAMP_MASK);
  WRAP_CONSTANT(SND_SEQ_TIME_MODE_ABS);
  WRAP_CONSTANT(SND_SEQ_TIME_MODE_REL);
  WRAP_CONSTANT(SND_SEQ_TIME_MODE_MASK);
  WRAP_CONSTANT(SND_SEQ_EVENT_LENGTH_FIXED);
  WRAP_CONSTANT(SND_SEQ_EVENT_LENGTH_VARIABLE);
  WRAP_CONSTANT(SND_SEQ_EVENT_LENGTH_VARUSR);
  WRAP_CONSTANT(SND_SEQ_EVENT_LENGTH_MASK);
  WRAP_CONSTANT(SND_SEQ_PRIORITY_NORMAL);
  WRAP_CONSTANT(SND_SEQ_PRIORITY_HIGH);
  WRAP_CONSTANT(SND_SEQ_PRIORITY_MASK);

  WRAP_CONSTANT(MIDI_CTL_MSB_BANK);
  WRAP_CONSTANT(MIDI_CTL_MSB_MODWHEEL);
  WRAP_CONSTANT(MIDI_CTL_MSB_BREATH);
  WRAP_CONSTANT(MIDI_CTL_MSB_FOOT);
  WRAP_CONSTANT(MIDI_CTL_MSB_PORTAMENTO_TIME);
  WRAP_CONSTANT(MIDI_CTL_MSB_DATA_ENTRY);
  WRAP_CONSTANT(MIDI_CTL_MSB_MAIN_VOLUME);
  WRAP_CONSTANT(MIDI_CTL_MSB_BALANCE);
  WRAP_CONSTANT(MIDI_CTL_MSB_PAN);
  WRAP_CONSTANT(MIDI_CTL_MSB_EXPRESSION);
  WRAP_CONSTANT(MIDI_CTL_MSB_EFFECT1);
  WRAP_CONSTANT(MIDI_CTL_MSB_EFFECT2);
  WRAP_CONSTANT(MIDI_CTL_MSB_GENERAL_PURPOSE1);
  WRAP_CONSTANT(MIDI_CTL_MSB_GENERAL_PURPOSE2);
  WRAP_CONSTANT(MIDI_CTL_MSB_GENERAL_PURPOSE3);
  WRAP_CONSTANT(MIDI_CTL_MSB_GENERAL_PURPOSE4);
  WRAP_CONSTANT(MIDI_CTL_LSB_BANK);
  WRAP_CONSTANT(MIDI_CTL_LSB_MODWHEEL);
  WRAP_CONSTANT(MIDI_CTL_LSB_BREATH);
  WRAP_CONSTANT(MIDI_CTL_LSB_FOOT);
  WRAP_CONSTANT(MIDI_CTL_LSB_PORTAMENTO_TIME);
  WRAP_CONSTANT(MIDI_CTL_LSB_DATA_ENTRY);
  WRAP_CONSTANT(MIDI_CTL_LSB_MAIN_VOLUME);
  WRAP_CONSTANT(MIDI_CTL_LSB_BALANCE);
  WRAP_CONSTANT(MIDI_CTL_LSB_PAN);
  WRAP_CONSTANT(MIDI_CTL_LSB_EXPRESSION);
  WRAP_CONSTANT(MIDI_CTL_LSB_EFFECT1);
  WRAP_CONSTANT(MIDI_CTL_LSB_EFFECT2);
  WRAP_CONSTANT(MIDI_CTL_LSB_GENERAL_PURPOSE1);
  WRAP_CONSTANT(MIDI_CTL_LSB_GENERAL_PURPOSE2);
  WRAP_CONSTANT(MIDI_CTL_LSB_GENERAL_PURPOSE3);
  WRAP_CONSTANT(MIDI_CTL_LSB_GENERAL_PURPOSE4);
  WRAP_CONSTANT(MIDI_CTL_SUSTAIN);
  WRAP_CONSTANT(MIDI_CTL_PORTAMENTO);
  WRAP_CONSTANT(MIDI_CTL_SOSTENUTO);
  WRAP_CONSTANT(MIDI_CTL_SOFT_PEDAL);
  WRAP_CONSTANT(MIDI_CTL_LEGATO_FOOTSWITCH);
  WRAP_CONSTANT(MIDI_CTL_HOLD2);
  WRAP_CONSTANT(MIDI_CTL_SC1_SOUND_VARIATION);
  WRAP_CONSTANT(MIDI_CTL_SC2_TIMBRE);
  WRAP_CONSTANT(MIDI_CTL_SC3_RELEASE_TIME);
  WRAP_CONSTANT(MIDI_CTL_SC4_ATTACK_TIME);
  WRAP_CONSTANT(MIDI_CTL_SC5_BRIGHTNESS);
  WRAP_CONSTANT(MIDI_CTL_SC6);
  WRAP_CONSTANT(MIDI_CTL_SC7);
  WRAP_CONSTANT(MIDI_CTL_SC8);
  WRAP_CONSTANT(MIDI_CTL_SC9);
  WRAP_CONSTANT(MIDI_CTL_SC10);
  WRAP_CONSTANT(MIDI_CTL_GENERAL_PURPOSE5);
  WRAP_CONSTANT(MIDI_CTL_GENERAL_PURPOSE6);
  WRAP_CONSTANT(MIDI_CTL_GENERAL_PURPOSE7);
  WRAP_CONSTANT(MIDI_CTL_GENERAL_PURPOSE8);
  WRAP_CONSTANT(MIDI_CTL_PORTAMENTO_CONTROL);
  WRAP_CONSTANT(MIDI_CTL_E1_REVERB_DEPTH);
  WRAP_CONSTANT(MIDI_CTL_E2_TREMOLO_DEPTH);
  WRAP_CONSTANT(MIDI_CTL_E3_CHORUS_DEPTH);
  WRAP_CONSTANT(MIDI_CTL_E4_DETUNE_DEPTH); // CELESTE
  WRAP_CONSTANT(MIDI_CTL_E5_PHASER_DEPTH);
  WRAP_CONSTANT(MIDI_CTL_DATA_INCREMENT);
  WRAP_CONSTANT(MIDI_CTL_DATA_DECREMENT);
  WRAP_CONSTANT(MIDI_CTL_NONREG_PARM_NUM_LSB);
  WRAP_CONSTANT(MIDI_CTL_NONREG_PARM_NUM_MSB);
  WRAP_CONSTANT(MIDI_CTL_REGIST_PARM_NUM_LSB);
  WRAP_CONSTANT(MIDI_CTL_REGIST_PARM_NUM_MSB);
  WRAP_CONSTANT(MIDI_CTL_ALL_SOUNDS_OFF);
  WRAP_CONSTANT(MIDI_CTL_RESET_CONTROLLERS); // single channel
  WRAP_CONSTANT(MIDI_CTL_LOCAL_CONTROL_SWITCH);
  WRAP_CONSTANT(MIDI_CTL_ALL_NOTES_OFF);
  WRAP_CONSTANT(MIDI_CTL_OMNI_OFF);
  WRAP_CONSTANT(MIDI_CTL_OMNI_ON);
  WRAP_CONSTANT(MIDI_CTL_MONO1);
  WRAP_CONSTANT(MIDI_CTL_MONO2);
  WRAP_CONSTANT(MIDI_CHANNELS); // 16
  WRAP_CONSTANT(MIDI_GM_DRUM_CHANNEL); // 9, not 10 (counting from 0)

#define RB_DEF_IS_TYPE_METHOD(nam) \
  rb_define_method(alsaMidiEventClass,  #nam "_type?", RUBY_METHOD_FUNC(wrap_snd_seq_ev_is_##nam##_type), 0);
#define IS_TYPE_EXPANSION RB_DEF_IS_TYPE_METHOD
  IS_TYPE_EXPANSIONS
#define EV_IS_EXPANSION(nam) \
  rb_define_method(alsaMidiEventClass, #nam "?", RUBY_METHOD_FUNC(wrap_snd_seq_ev_is_##nam), 0);
  EV_IS_EXPANSIONS

  rb_define_method(alsaMidiEventClass, "type_check?", RUBY_METHOD_FUNC(wrap_snd_seq_type_check), 1);

  // ev.data.ext.len
  rb_define_method(alsaMidiEventClass, "len", RUBY_METHOD_FUNC(alsaMidiEventClass_len), 0);

  /* this is the size required on the output. */
  rb_define_method(alsaMidiEventClass, "length", RUBY_METHOD_FUNC(wrap_snd_seq_event_length), 0);

  rb_define_method(alsaMidiEventClass, "time", RUBY_METHOD_FUNC(alsaMidiEventClass_time), 0);

  rb_define_method(alsaMidiEventClass, "time_tick", RUBY_METHOD_FUNC(alsaMidiEventClass_time_tick), 0);
  rb_define_method(alsaMidiEventClass, "time_tick=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_time_tick), 1);

  // VOICE: valid for note + control:
  rb_define_method(alsaMidiEventClass, "channel", RUBY_METHOD_FUNC(alsaMidiEventClass_channel), 0);
  rb_define_method(alsaMidiEventClass, "channel=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_channel), 1);

  // NOTEON/OFF (<VOICE)
  rb_define_method(alsaMidiEventClass, "note", RUBY_METHOD_FUNC(alsaMidiEventClass_note), 0);
  rb_define_method(alsaMidiEventClass, "note=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_note), 1);
  rb_define_method(alsaMidiEventClass, "velocity", RUBY_METHOD_FUNC(alsaMidiEventClass_velocity), 0);
  rb_define_method(alsaMidiEventClass, "velocity=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_velocity), 1);
  // NoTE only (<NOTEON)
  rb_define_method(alsaMidiEventClass, "off_velocity", RUBY_METHOD_FUNC(alsaMidiEventClass_off_velocity), 0);
  rb_define_method(alsaMidiEventClass, "off_velocity=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_off_velocity), 1);
  rb_define_method(alsaMidiEventClass, "duration", RUBY_METHOD_FUNC(alsaMidiEventClass_duration), 0);
  rb_define_method(alsaMidiEventClass, "duration=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_duration), 1);
  // CONTROLLER (<VOICE):
  rb_define_method(alsaMidiEventClass, "param", RUBY_METHOD_FUNC(alsaMidiEventClass_param), 0);
  rb_define_method(alsaMidiEventClass, "param=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_param), 1);
  rb_define_method(alsaMidiEventClass, "value", RUBY_METHOD_FUNC(alsaMidiEventClass_value), 0);
  rb_define_method(alsaMidiEventClass, "value=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_value), 1);
  rb_define_method(alsaMidiEventClass, "sysex", RUBY_METHOD_FUNC(alsaMidiEventClass_sysex), 0);
  // ALL:
  rb_define_method(alsaMidiEventClass, "type", RUBY_METHOD_FUNC(alsaMidiEventClass_type), 0);
  rb_define_method(alsaMidiEventClass, "type=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_type), 1);

  rb_define_method(alsaMidiEventClass, "source", RUBY_METHOD_FUNC(alsaMidiEventClass_source), 0);
  rb_define_method(alsaMidiEventClass, "source_port", RUBY_METHOD_FUNC(alsaMidiEventClass_source_port), 0);
  rb_define_method(alsaMidiEventClass, "source_client", RUBY_METHOD_FUNC(alsaMidiEventClass_source_client), 0);
   // IMPORTANT: source=  IS NOT snd_seq_ev_set_source!!!!
  rb_define_method(alsaMidiEventClass, "source=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_source), -1);
  rb_define_method(alsaMidiEventClass, "source_port=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_source_port), 1);
  rb_define_method(alsaMidiEventClass, "source_client=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_source_client), 1);
  rb_define_method(alsaMidiEventClass, "dest", RUBY_METHOD_FUNC(alsaMidiEventClass_dest), 0);
  rb_define_method(alsaMidiEventClass, "dest_port", RUBY_METHOD_FUNC(alsaMidiEventClass_dest_port), 0);
  rb_define_method(alsaMidiEventClass, "dest_client", RUBY_METHOD_FUNC(alsaMidiEventClass_dest_client), 0);
  rb_define_method(alsaMidiEventClass, "dest=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_dest), -1);
  rb_define_method(alsaMidiEventClass, "dest_port=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_dest_port), 1);
  rb_define_method(alsaMidiEventClass, "dest_client=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_dest_client), 1);

  rb_define_method(alsaMidiEventClass, "clear", RUBY_METHOD_FUNC(wrap_snd_seq_ev_clear), 0);
  rb_define_method(alsaMidiEventClass, "queue", RUBY_METHOD_FUNC(alsaMidiEventClass_queue), 0);
  rb_define_method(alsaMidiEventClass, "queue=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_queue), 1);
  rb_define_method(alsaMidiEventClass, "flags", RUBY_METHOD_FUNC(alsaMidiEventClass_flags), 0);
  rb_define_method(alsaMidiEventClass, "flags=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_flags), 1);
  rb_define_method(alsaMidiEventClass, "set_note", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_note), 4);
  rb_define_method(alsaMidiEventClass, "schedule_tick", RUBY_METHOD_FUNC(wrap_snd_seq_ev_schedule_tick), 3);
  rb_define_method(alsaMidiEventClass, "schedule_real", RUBY_METHOD_FUNC(wrap_snd_seq_ev_schedule_real), 3);
  rb_define_method(alsaMidiEventClass, "set_pgmchange", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_pgmchange), 2);
  rb_define_method(alsaMidiEventClass, "set_pitchbend", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_pitchbend), 2);
  rb_define_method(alsaMidiEventClass, "set_chanpress", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_chanpress), 2);


  /* IMPORTANT! the alsa docs (if you can call it that) say nothing about dynamic allocation
  of the buffer (is it copied somewhere?). Does the caller need to make sure it stays
  alive until the event is dispatched?

  Assigning a ruby string may will cause a SEGV as ruby will free the string at some time, which
  would invalidate the buffer!!
  */
  rb_define_method(alsaMidiEventClass, "sysex=", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_sysex), 1);


  rb_define_method(alsaMidiEventClass, "set_noteon", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_noteon), 3);
  rb_define_method(alsaMidiEventClass, "set_noteoff", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_noteoff), -1);
  rb_define_method(alsaMidiEventClass, "set_keypress", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_keypress), 3);
  rb_define_method(alsaMidiEventClass, "set_controller", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_controller), 3);

  rb_define_method(alsaMidiEventClass, "set_subs", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_subs), 0);
  rb_define_method(alsaMidiEventClass, "set_broadcast_to_subscribers", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_subs), 0);
//   rb_define_method(alsaMidiEventClass, "broadcast_to_subscribers", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_subs), 0);

  rb_define_method(alsaMidiEventClass, "tag=", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_tag), 1);
  rb_define_method(alsaMidiEventClass, "set_broadcast", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_broadcast), 0);
//   rb_define_method(alsaMidiEventClass, "broadcast", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_broadcast), 0);
  rb_define_method(alsaMidiEventClass, "set_direct", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_direct), 0);
//   rb_define_method(alsaMidiEventClass, "direct", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_direct), 0);
  rb_define_method(alsaMidiEventClass, "priority=", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_priority), 1);
  rb_define_method(alsaMidiEventClass, "set_fixed", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_fixed), 0);
//   rb_define_method(alsaMidiEventClass, "fixed", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_fixed), 0);
  rb_define_method(alsaMidiEventClass, "set_variable", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_variable), 1);
  rb_define_method(alsaMidiEventClass, "set_varusr", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_varusr), 1);
  rb_define_method(alsaMidiEventClass, "queue_queue", RUBY_METHOD_FUNC(alsaMidiEventClass_queue_queue), 0);
  rb_define_method(alsaMidiEventClass, "queue_queue=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_queue_queue), 1);
  rb_define_method(alsaMidiEventClass, "set_queue_control", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_queue_control), 3);
  rb_define_method(alsaMidiEventClass, "set_queue_start", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_queue_start), 1);
  rb_define_method(alsaMidiEventClass, "set_queue_stop", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_queue_stop), 1);
  rb_define_method(alsaMidiEventClass, "set_queue_continue", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_queue_continue), 1);
  rb_define_method(alsaMidiEventClass, "set_queue_tempo", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_queue_tempo), 2);
  rb_define_method(alsaMidiEventClass, "set_queue_pos_real", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_queue_pos_real), 2);
  rb_define_method(alsaMidiEventClass, "set_queue_pos_tick", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_queue_pos_tick), 2);
  rb_define_method(alsaMidiEventClass, "queue_value", RUBY_METHOD_FUNC(alsaMidiEventClass_queue_value), 0);
  rb_define_method(alsaMidiEventClass, "queue_value=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_queue_value), 1);
  rb_define_method(alsaMidiEventClass, "queue_position", RUBY_METHOD_FUNC(alsaMidiEventClass_queue_position), 0);
  rb_define_method(alsaMidiEventClass, "queue_position=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_queue_position), 1);
  rb_define_method(alsaMidiEventClass, "queue_skew", RUBY_METHOD_FUNC(alsaMidiEventClass_queue_skew), 0);
  rb_define_method(alsaMidiEventClass, "queue_skew=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_queue_skew), -1);
  rb_define_method(alsaMidiEventClass, "time=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_time), -1);
  rb_define_method(alsaMidiEventClass, "time_real", RUBY_METHOD_FUNC(alsaMidiEventClass_time_real), 0);
  rb_define_method(alsaMidiEventClass, "time_real=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_time_real), -1);
  rb_define_method(alsaMidiEventClass, "queue_time", RUBY_METHOD_FUNC(alsaMidiEventClass_queue_time), 0);
  rb_define_method(alsaMidiEventClass, "queue_time_tick", RUBY_METHOD_FUNC(alsaMidiEventClass_queue_time_tick), 0);
  rb_define_method(alsaMidiEventClass, "queue_time_real", RUBY_METHOD_FUNC(alsaMidiEventClass_queue_time_real), 0);
  rb_define_method(alsaMidiEventClass, "queue_time=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_queue_time), -1);
  rb_define_method(alsaMidiEventClass, "queue_time_tick=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_queue_time_tick), 1);
  rb_define_method(alsaMidiEventClass, "queue_time_real=", RUBY_METHOD_FUNC(alsaMidiEventClass_set_queue_time_real), -1);
  rb_define_method(alsaMidiEventClass, "inspect", RUBY_METHOD_FUNC(alsaMidiEventClass_inspect), 0);
}
