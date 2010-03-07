
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

// string AlsaMidiEvent_i#inspect
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

/* self AlsaMidiEvent_i#clear
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
This causes the event to be broadcast to all subscribers of the connection
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

Set the queue and the specified eventtime
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
Sets the queue and time for the event. The subscription must support this.
*/
static VALUE
wrap_snd_seq_ev_schedule_real(VALUE v_ev, VALUE v_qid, VALUE v_relative, VALUE v_timetuple)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  v_timetuple = rb_check_array_type(v_timetuple);
  if (!RTEST(v_timetuple)) RAISE_MIDI_ERROR_FMT0("bad realtime for schedule_real");
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
int AlsaMidiEvent_i#length
calculates the (encoded) byte-stream size of the event

Parameters:
ev      the event

Returns:
the size of decoded bytes, ie. the number of bytes (including message formatting)
required to send the event.
*/
static VALUE
wrap_snd_seq_event_length(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
// HAHAHA   fprintf(stderr, "snd_seq_event_length is prone to crashes!!!! Hold yer horses!\n");
  return INT2NUM(snd_seq_event_length(ev));
}

/* int AlsaMidiEvent_i#note
*/
static VALUE
alsaMidiEventClass_note(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_note_type(ev)) return Qnil;
  return UINT2NUM(ev->data.note.note);
}

// AlsaMidiEvent_i#note= value
static VALUE
alsaMidiEventClass_set_note(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.note.note = NUM2UINT(v_val);
  return Qnil;
}

// AlsaMidiEvent_i#velocity= value
static VALUE
alsaMidiEventClass_set_velocity(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.note.velocity = NUM2UINT(v_val);
  return Qnil;
}

// AlsaMidiEvent_i#off_velocity= value
static VALUE
alsaMidiEventClass_set_off_velocity(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.note.off_velocity = NUM2UINT(v_val);
  return Qnil;
}

// AlsaMidiEvent_i#duration= value
static VALUE
alsaMidiEventClass_set_duration(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.note.duration = NUM2UINT(v_val);
  return Qnil;
}

/* int AlsaMidiEvent_i#channel
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

/* AlsaMidiEvent_i#channel= ch
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

// int AlsaMidiEvent_i#queue
static VALUE
alsaMidiEventClass_queue(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->queue);
}

// AlsaMidiEvent_i#queue=
static VALUE
alsaMidiEventClass_set_queue(VALUE v_ev, VALUE v_queue)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  RRTS_DEREF_DIRTY(v_queue, @id);
  ev->queue = NUM2INT(v_queue);
  return Qnil;
}

// int AlsaMidiEvent_i#queue
static VALUE
alsaMidiEventClass_queue_queue(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return UINT2NUM(ev->data.queue.queue);
}

// AlsaMidiEvent_i#queue_queue=
static VALUE
alsaMidiEventClass_set_queue_queue(VALUE v_ev, VALUE v_queue)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  RRTS_DEREF_DIRTY(v_queue, @id);
  ev->data.queue.queue = NUM2UINT(v_queue);
  return Qnil;
}

// int AlsaMidiEvent_i#flags
static VALUE
alsaMidiEventClass_flags(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return UINT2NUM(ev->flags);
}

// AlsaMidiEvent_i#flags=
static VALUE
alsaMidiEventClass_set_flags(VALUE v_ev, VALUE v_flags)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->flags = NUM2UINT(v_flags);
  return Qnil;
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

// AlsaMidiEvent_i#param= value
static VALUE
alsaMidiEventClass_set_param(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.control.param = NUM2UINT(v_val);
  return Qnil;
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

// AlsaMidiEvent_i#value= val
static VALUE
alsaMidiEventClass_set_value(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.control.value = NUM2INT(v_val);
  return Qnil;
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

// AlsaMidiEvent_i#type=
static VALUE
alsaMidiEventClass_set_type(VALUE v_ev, VALUE v_tp)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->type = NUM2INT(v_tp);
  return Qnil;
}

/* int AlsaMidiEvent_i#len. Better use sysex.length
   Also do not confuse with length.
*/
static VALUE
alsaMidiEventClass_len(VALUE v_ev)
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
  RRTS_DEREF_DIRTY(v_portid, @port);
  ev->source.port = NUM2INT(v_portid);
  return Qnil;
}

// skewvalue, base AlsaMidiEvent_i#queue_skew
static VALUE
alsaMidiEventClass_queue_skew(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return rb_ary_new3(2, UINT2NUM(ev->data.queue.param.skew.value), UINT2NUM(ev->data.queue.param.skew.base));
}

/* AlsaMidiEvent_i#queue_skew= [value, base]
AlsaMidiEvent_i#queue_skew= value, base
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

/* AlsaMidiEvent_i#time= ticks
AlsaMidiEvent_i#time= sec, nsec
AlsaMidiEvent_i#time= [sec, nsec]
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
      v_sec = rb_check_array_type(v_sec);
      if (!RTEST(v_sec)) RAISE_MIDI_ERROR_FMT0("API call error: bad time format");
      v_nsec = rb_ary_entry(v_sec, 1);
      v_sec = rb_ary_entry(v_sec, 0);
    }
  ev->time.time.tv_sec = NUM2UINT(v_sec);
  ev->time.time.tv_nsec = NUM2UINT(v_nsec);
  return Qnil;
}

static VALUE
alsaMidiEventClass_time_real(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return rb_ary_new3(2, UINT2NUM(ev->time.time.tv_sec), UINT2NUM(ev->time.time.tv_nsec));
}

/*
AlsaMidiEvent_i#time_real= sec, nsec
AlsaMidiEvent_i#time_real= [sec, nsec]
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
    v_sec = rb_check_array_type(v_sec);
    if (!RTEST(v_sec)) RAISE_MIDI_ERROR_FMT0("API call error: realtime needs sec+nsec tuple");
    v_nsec = rb_ary_entry(v_sec, 1);
    v_sec = rb_ary_entry(v_sec, 0);
  }
  ev->time.time.tv_sec = NUM2UINT(v_sec);
  ev->time.time.tv_nsec = NUM2UINT(v_nsec);
  return Qnil;
}

/* AlsaMidiEvent_i#queue_time= ticks
AlsaMidiEvent_i#queue_time= sec, nsec
AlsaMidiEvent_i#queue_time= [sec, nsec]
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
    v_sec = rb_check_array_type(v_sec);
    if (!RTEST(v_sec)) RAISE_MIDI_ERROR_FMT0("API call error: bad time format");
    v_nsec = rb_ary_entry(v_sec, 1);
    v_sec = rb_ary_entry(v_sec, 0);
  }
  ev->data.queue.param.time.time.tv_sec = NUM2UINT(v_sec);
  ev->data.queue.param.time.time.tv_nsec = NUM2UINT(v_nsec);
  return Qnil;
}

// sec, nsec AlsaMidiEvent_i#time_real
static VALUE
alsaMidiEventClass_queue_time_real(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return rb_ary_new3(2, UINT2NUM(ev->data.queue.param.time.time.tv_sec),
                        UINT2NUM(ev->data.queue.param.time.time.tv_nsec));
}

/*
AlsaMidiEvent_i#queue_time_real= sec, nsec
AlsaMidiEvent_i#queue_time_real= [sec, nsec]
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
    v_sec = rb_check_array_type(v_sec);
    if (!RTEST(v_sec)) RAISE_MIDI_ERROR_FMT0("API call error: realtime needs sec+nsec tuple");
    v_nsec = rb_ary_entry(v_sec, 1);
    v_sec = rb_ary_entry(v_sec, 0);
  }
  ev->data.queue.param.time.time.tv_sec = NUM2UINT(v_sec);
  ev->data.queue.param.time.time.tv_nsec = NUM2UINT(v_nsec);
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

/* AlsaMidiEvent_i#time_tick= value
*/
static VALUE
alsaMidiEventClass_set_time_tick(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->time.tick = NUM2UINT(v_val);
  return Qnil;
}

// int AlsaMidiEvent_i#queue_value
static VALUE
alsaMidiEventClass_queue_value(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return INT2NUM(ev->data.queue.param.value);
}

// AlsaMidiEvent_i#queue_value= value
static VALUE
alsaMidiEventClass_set_queue_value(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.queue.param.value = NUM2INT(v_val);
  return Qnil;
}

// int AlsaMidiEvent_i#queue_time.  This may be wrong so snd_seq_ev_is_real is used.
// Assuming hence, that time and queue.time have the same format.
static VALUE
alsaMidiEventClass_queue_time(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  const snd_seq_timestamp_t &t = ev->data.queue.param.time;
  const bool real = snd_seq_ev_is_real(ev);
  if (real)
  {
    VALUE v_secs = UINT2NUM(t.time.tv_sec);
    VALUE v_nsecs = UINT2NUM(t.time.tv_nsec);
    return rb_ary_new3(2, v_secs, v_nsecs);
  }
  return UINT2NUM(t.tick);
}

/* int AlsaMidiEvent_i#queue_time_tick
*/
static VALUE
alsaMidiEventClass_queue_time_tick(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  if (!snd_seq_ev_is_tick(ev)) return Qnil;
  return UINT2NUM(ev->data.queue.param.time.tick);
}

/* AlsaMidiEvent_i#queue_time_tick= value
*/
static VALUE
alsaMidiEventClass_set_queue_time_tick(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.queue.param.time.tick = NUM2UINT(v_val);
  return Qnil;
}

// int AlsaMidiEvent_i#queue_position
static VALUE
alsaMidiEventClass_queue_position(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return UINT2NUM(ev->data.queue.param.position);
}

// AlsaMidiEvent_i#queue_position= value
static VALUE
alsaMidiEventClass_set_queue_position(VALUE v_ev, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  ev->data.queue.param.position = NUM2UINT(v_val);
  return Qnil;
}

// ALSA internal ???? What's a tag???
static VALUE
wrap_snd_seq_ev_set_tag(VALUE v_ev, VALUE v_tag)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_tag(ev, NUM2UINT(v_tag));
  return Qnil;
}

// Specify that the event must be broadcast to ALL clients on the system
static VALUE
wrap_snd_seq_ev_set_broadcast(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_broadcast(ev);
  return Qnil;
}

/* Specify that the event does not use a queue and is send immediately.
If neither a schedule is perfomed, and 'direct' is not set, then the event
is still buffered and will only be send on a flush
*/
static VALUE
wrap_snd_seq_ev_set_direct(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_direct(ev);
  return Qnil;
}

// specify that the event has a high priority
static VALUE
wrap_snd_seq_ev_set_priority(VALUE v_ev, VALUE v_prio)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_priority(ev, NUM2INT(v_prio));
  return Qnil;
}

// specify that the event has a fixed length.
static VALUE
wrap_snd_seq_ev_set_fixed(VALUE v_ev)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_fixed(ev);
  return Qnil;
}

// Set variable data, makes it a sysex
static VALUE
wrap_snd_seq_ev_set_variable(VALUE v_ev, VALUE v_data)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  Check_Type(v_data, T_STRING);
  snd_seq_ev_set_variable(ev, RSTRING_LEN(v_data), RSTRING_PTR(v_data));
  return Qnil;
}

// set a varusr event's data
static VALUE
wrap_snd_seq_ev_set_varusr(VALUE v_ev, VALUE v_data)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  Check_Type(v_data, T_STRING);
  snd_seq_ev_set_varusr(ev, RSTRING_LEN(v_data), RSTRING_PTR(v_data));
  return Qnil;
}

// Utility 'macro' for the other queue_control macro's
static VALUE
wrap_snd_seq_ev_set_queue_control(VALUE v_ev, VALUE v_tp, VALUE v_q, VALUE v_val)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_queue_control(ev, NUM2INT(v_tp), NUM2UINT(v_q), NUM2INT(v_val));
  return Qnil;
}

// make it a start queue event
static VALUE
wrap_snd_seq_ev_set_queue_start(VALUE v_ev, VALUE v_q)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_queue_start(ev, NUM2UINT(v_q));
  return Qnil;
}

// make it a stop queue event
static VALUE
wrap_snd_seq_ev_set_queue_stop(VALUE v_ev, VALUE v_q)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_queue_stop(ev, NUM2UINT(v_q));
  return Qnil;
}

// make it a queue continue event
static VALUE
wrap_snd_seq_ev_set_queue_continue(VALUE v_ev, VALUE v_q)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_queue_continue(ev, NUM2UINT(v_q));
  return Qnil;
}

// make it a set queue tempo event
static VALUE
wrap_snd_seq_ev_set_queue_tempo(VALUE v_ev, VALUE v_q, VALUE v_tempo)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_queue_tempo(ev, NUM2UINT(v_q), NUM2UINT(v_tempo));
  return Qnil;
}

// perform a realtime seek, changes current position in queue
static VALUE
wrap_snd_seq_ev_set_queue_pos_real(VALUE v_ev, VALUE v_q, VALUE v_timetuple)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  v_timetuple = rb_check_array_type(v_timetuple);
  if (!RTEST(v_timetuple)) RAISE_MIDI_ERROR_FMT0("bad realtime for queuepos_real");
  VALUE secs = rb_ary_entry(v_timetuple, 0), nsecs = rb_ary_entry(v_timetuple, 1);
  const snd_seq_real_time tm = { NUM2UINT(secs), NUM2UINT(nsecs) };
  snd_seq_ev_set_queue_pos_real(ev, NUM2UINT(v_q), &tm);
  return Qnil;
}

// perform a seek in the queue, altering the current position
// events are skipped or resend
static VALUE
wrap_snd_seq_ev_set_queue_pos_tick(VALUE v_ev, VALUE v_q, VALUE v_ticks)
{
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_ev_set_queue_pos_tick(ev, NUM2UINT(v_q), NUM2UINT(v_ticks));
  return Qnil;
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
  rb_define_method(alsaMidiEventClass, "set_noteoff", RUBY_METHOD_FUNC(wrap_snd_seq_ev_set_noteoff), 3);
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
