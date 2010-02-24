
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

//  DOC on all events + types http://alsa-project.org/alsa-doc/alsa-lib/group___seq_events.html

VALUE alsaMidiEventClass;

// self AlsaMidiEvent_i#clear
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

// self AlsaMidiEvent_i#set_note ch, key, vel, dur
static VALUE  // ch key vel dur
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

// self AlsaMidiEvent_i#set_pgmchange ch, val
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

// self AlsaMidiEvent_i#set_pitchbend ch, val
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

// self AlsaMidiEvent_i#set_chanpress ch, val
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

/* AlsaMidiEvent_i#sysex = data
IMPORTANT! the alsa docs (if you can call it that) say nothing about dynamic allocation
of the buffer (is it copied somewhere?). Does the caller need to make sure it stays
alive until the event is dispatched?

Assigning a ruby string may will cause a SEGV as ruby will free the string at some time, which
would invalidate the buffer!!

TODO: look this up in the alsa source files.
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

// self AlsaMidiEvent_i#set_noteon ch, key, vel
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

// self AlsaMidiEvent_i#set_noteoff ch, key, vel
static VALUE
wrap_snd_seq_ev_set_noteoff(VALUE v_ev, VALUE v_ch, VALUE v_key, VALUE v_vel)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_set_noteoff(%p, %d, %d, %d)\n", ev, NUM2INT(v_ch), NUM2INT(v_key), NUM2INT(v_vel));
#endif
  snd_seq_ev_set_noteoff(ev, NUM2UINT(v_ch), NUM2UINT(v_key), NUM2UINT(v_vel));
  return v_ev;
}

// self AlsaMidiEvent_i#set_keypress ch, key, vel
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

// self AlsaMidiEvent_i#set_controller ch, cc, val
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

/* self AlsaMidiEvent_i#set_subs
sets the destination to 'SUBSCRIBERS:UNKNOWN', a special client+port
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

/*
self AlsaMidiEvent_i schedule_tick qid, relative, tick
self AlsaMidiEvent_i schedule_tick MidiQueue, relative, tick
*/
static VALUE
wrap_snd_seq_ev_schedule_tick(VALUE v_ev, VALUE v_qid, VALUE v_relative, VALUE v_tick)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  RRTS_DEREF(v_qid, id);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_schedule_tick(%p, %d, %s, %ud)\n", ev, NUM2INT(v_qid), BOOL2INT(v_relative) ? "true" : "false", NUM2UINT(v_tick));
#endif
  snd_seq_ev_schedule_tick(ev, NUM2INT(v_qid), BOOL2INT(v_relative), NUM2UINT(v_tick));
  return v_ev;
}

/* self AlsaMidiEvent_i schedule_real qid, relative, timetuple
*/
static VALUE
wrap_snd_seq_ev_schedule_real(VALUE v_ev, VALUE v_qid, VALUE v_relative, VALUE v_timetuple)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  VALUE secs = rb_ary_entry(v_timetuple, 0), nsecs = rb_ary_entry(v_timetuple, 1);
  const snd_seq_real_time tm = { NUM2UINT(secs), NUM2UINT(nsecs) };
  #if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_ev_schedule_real(%p, %d, %s, %ud-%ud)\n", ev, NUM2INT(v_qid), BOOL2INT(v_relative) ? "true" : "false", tm.tv_sec, tm.tv_nsec);
  #endif
  snd_seq_ev_schedule_real(ev, NUM2INT(v_qid), BOOL2INT(v_relative), &tm);
  return v_ev;
}

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

/* bool AlsaMidiEvent_i#type_check flags
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

/*
ssize_t snd_seq_event_length    (       snd_seq_event_t *        ev      )

calculates the (encoded) byte-stream size of the event

Parameters:
ev      the event

Returns:
the size of decoded bytes
*/
// static VALUE
// wrap_snd_seq_event_length(VALUE v_ev)
// {
//   snd_seq_event_t *ev;
//   Data_Get_Struct(v_ev, snd_seq_event_t, ev);
//   fprintf(stderr, "CRASHES!! ev=%p\n", ev);
//   return NUM2INT(snd_seq_event_length(ev));
// }

/* int AlsaMidiEvent_i#note
*/
static VALUE
alsaMidiEventClass_note(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_note_type(ev)) return Qnil;
  return INT2NUM(ev->data.note.note);
}

/* int AlsaMidiEvent_i#channel
Valid for note- and controlmessages
*/
static VALUE
alsaMidiEventClass_channel(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (snd_seq_ev_is_note_type(ev))
    return INT2NUM(ev->data.note.channel);
  if (snd_seq_ev_is_control_type(ev))
    return INT2NUM(ev->data.control.channel);
//   RAISE_MIDI_ERROR_FMT1("ev %d has no channel", ev->type);
  return Qnil;
}

// int AlsaMidiEvent_i#queue
static VALUE
alsaMidiEventClass_queue(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->queue);
}

// int AlsaMidiEvent_i#param
static VALUE
alsaMidiEventClass_param(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_control_type(ev)) return Qnil;
  return UINT2NUM(ev->data.control.param);
}

// int AlsaMidiEvent_i#value
static VALUE
alsaMidiEventClass_value(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  /*  if (snd_seq_ev_is_variable_type(ev))
  {
    const uint len = ev->data.ext.len;
    return rb_str_new((const char *)ev->data.ext.ptr, len);
}*/
  if (!snd_seq_ev_is_control_type(ev)) return Qnil;
  return INT2NUM(ev->data.control.value);
}

// string AlsaMidiEvent_i#sysex
static VALUE
alsaMidiEventClass_sysex(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_variable_type(ev)) return Qnil; // ???
  const uint len = ev->data.ext.len;
  return rb_str_new((const char *)ev->data.ext.ptr, len);
}

// int AlsaMidiEvent_i#velocity
static VALUE
alsaMidiEventClass_velocity(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_note_type(ev)) return Qnil;
  return INT2NUM(ev->data.note.velocity);
}

// int AlsaMidiEvent_i#type
static VALUE
alsaMidiEventClass_type(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->type);
}

// int AlsaMidiEvent_i#length
static VALUE
alsaMidiEventClass_length(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_variable_type(ev)) return Qnil; // ???
  return UINT2NUM(ev->data.ext.len);
}

// int AlsaMidiEvent_i#off_velocity
static VALUE
alsaMidiEventClass_off_velocity(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_note_type(ev)) return Qnil;
  return INT2NUM(ev->data.note.off_velocity);
}

// int AlsaMidiEvent_i#duration
static VALUE
alsaMidiEventClass_duration(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_note_type(ev)) return Qnil;
  return INT2NUM(ev->data.note.duration);
}

// client, port AlsaMidiEvent_i#dest
static VALUE
alsaMidiEventClass_dest(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return rb_ary_new3(2, INT2NUM(ev->dest.client), INT2NUM(ev->dest.port));
}

// int AlsaMidiEvent_i#dest_port
static VALUE
alsaMidiEventClass_dest_port(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->dest.port);
}

// int AlsaMidiEvent_i#dest_client
static VALUE
alsaMidiEventClass_dest_client(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->dest.client);
}

// client, port AlsaMidiEvent_i#source
static VALUE
alsaMidiEventClass_source(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return rb_ary_new3(2, INT2NUM(ev->source.client), INT2NUM(ev->source.port));
}

// int AlsaMidiEvent_i#source_port
static VALUE
alsaMidiEventClass_source_port(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->source.port);
}

// int AlsaMidiEvent_i#source_client
static VALUE
alsaMidiEventClass_source_client(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->source.client);
}

#define FETCH_ADDRESSES() \
VALUE v_clientid, v_portid; \
rb_scan_args(argc, argv, "11", &v_clientid, &v_portid); \
solve_address(v_clientid, v_portid)

/* AlsaMidiEvent_i#source= addr
   AlsaMidiEvent_i#source= client, port

 IMPORTANT: this differs from the alsa API which suffers from a naming inconsistency.
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

// AlsaMidiEvent_i#source_client =
static VALUE
alsaMidiEventClass_set_source_client(VALUE v_ev, VALUE v_clientid)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->source.client = NUM2INT(v_clientid);
  return Qnil;
}

// AlsaMidiEvent_i#source_port =
static VALUE
alsaMidiEventClass_set_source_port(VALUE v_ev, VALUE v_portid)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->source.port = NUM2INT(v_portid);
  return Qnil;
}

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

// AlsaMidiEvent_i#dest_client =
static VALUE
alsaMidiEventClass_set_dest_client(VALUE v_ev, VALUE v_clientid)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->dest.client = NUM2INT(v_clientid);
  return Qnil;
}

// AlsaMidiEvent_i#dest_port =
static VALUE
alsaMidiEventClass_set_dest_port(VALUE v_ev, VALUE v_portid)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->dest.port = NUM2INT(v_portid);
  return Qnil;
}

/*
secs, nsect AlsaMidiEvent_i#time
ticks AlsaMidiEvent_i#time

Note: there is NO data associated with a CLOCK event
24 CLOCKS = 1/4 note.
So in 4/4 there are 96 CLOCKS in a bar,
and for 3/4 that would be 72.
1/8 12 clocks
1/16 6 clocks
1/32 3 clocks
*/
static VALUE
alsaMidiEventClass_time(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  //   fprintf(stderr, __FILE__ ":%d: ev->time.tick=%ud, ev->time.time.tv_sec=%ud,nsec=%ud\n", __LINE__, ev->time.tick, ev->time.time.tv_sec, ev->time.time.tv_nsec);
  snd_seq_timestamp_t t = ev->time;
  const bool real = snd_seq_ev_is_real(ev);
  if (real)
  {
    VALUE v_secs = UINT2NUM(t.time.tv_sec);
    VALUE v_nsecs = UINT2NUM(t.time.tv_nsec);
    return rb_ary_new3(2, v_secs, v_nsecs);
  }
  return UINT2NUM(t.tick);
}

/* int AlsaMidiEvent_i#time_tick
*/
static VALUE
alsaMidiEventClass_time_tick(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_tick(ev)) return Qnil;
  return UINT2NUM(ev->time.tick);
}

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

  WRAP_CONSTANT(MIDI_CHANNELS); // 16
  WRAP_CONSTANT(MIDI_GM_DRUM_CHANNEL); // 9 (ch 10)

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

#define RB_DEF_IS_TYPE_METHOD(nam) \
  rb_define_method(alsaMidiEventClass,  #nam "_type?", RUBY_METHOD_FUNC(wrap_snd_seq_ev_is_##nam##_type), 0);
#define IS_TYPE_EXPANSION RB_DEF_IS_TYPE_METHOD
  IS_TYPE_EXPANSIONS
#define EV_IS_EXPANSION(nam) \
  rb_define_method(alsaMidiEventClass, #nam "?", RUBY_METHOD_FUNC(wrap_snd_seq_ev_is_##nam), 0);
  EV_IS_EXPANSIONS

  rb_define_method(alsaMidiEventClass, "type_check?", RUBY_METHOD_FUNC(wrap_snd_seq_type_check), 1);
  rb_define_method(alsaMidiEventClass, "length", RUBY_METHOD_FUNC(alsaMidiEventClass_length), 0);

  // IMPORTANT: does not return ev.time !!!!!
  rb_define_method(alsaMidiEventClass, "time", RUBY_METHOD_FUNC(alsaMidiEventClass_time), 0);

  rb_define_method(alsaMidiEventClass, "time_tick", RUBY_METHOD_FUNC(alsaMidiEventClass_time_tick), 0);

  // VOICE:
  rb_define_method(alsaMidiEventClass, "channel", RUBY_METHOD_FUNC(alsaMidiEventClass_channel), 0);
  // NOTEON/OFF (<VOICE)
  rb_define_method(alsaMidiEventClass, "note", RUBY_METHOD_FUNC(alsaMidiEventClass_note), 0);
  rb_define_method(alsaMidiEventClass, "velocity", RUBY_METHOD_FUNC(alsaMidiEventClass_velocity), 0);
  // NoTE only (<NOTEON)
  rb_define_method(alsaMidiEventClass, "off_velocity", RUBY_METHOD_FUNC(alsaMidiEventClass_off_velocity), 0);
  rb_define_method(alsaMidiEventClass, "duration", RUBY_METHOD_FUNC(alsaMidiEventClass_duration), 0);
  // CONTROLLER (<VOICE):
  rb_define_method(alsaMidiEventClass, "param", RUBY_METHOD_FUNC(alsaMidiEventClass_param), 0);
  rb_define_method(alsaMidiEventClass, "value", RUBY_METHOD_FUNC(alsaMidiEventClass_value), 0);
  rb_define_method(alsaMidiEventClass, "sysex", RUBY_METHOD_FUNC(alsaMidiEventClass_sysex), 0);
  // ALL:
  rb_define_method(alsaMidiEventClass, "type", RUBY_METHOD_FUNC(alsaMidiEventClass_type), 0);

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
  rb_define_method(alsaMidiEventClass, "set_noteoff", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_noteoff), 3);
  rb_define_method(alsaMidiEventClass, "set_keypress", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_keypress), 3);
  rb_define_method(alsaMidiEventClass, "set_controller", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_controller), 3);
  rb_define_method(alsaMidiEventClass, "set_subs", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_subs), 0);

}
