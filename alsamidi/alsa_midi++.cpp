
#pragma implementation
#include "alsa_midi++.h"
#include "alsa_midi_event.h"
#include "alsa_midi.h"
#include "alsa_midi_queue.h"
#include "alsa_midi_client.h"

#include <ruby/dl.h>
#include <alsa/asoundlib.h>

static const char *evtypename[256] = {};

static inline void get_channel(VALUE v_midievent, int channel)
{
  rb_iv_set(v_midievent, "@channel", UINT2NUM((channel & 0xf) + 1));
}

/* AlsaMidiEvent_i#populate Sequencer, MidiEvent
To avoid confusion, the MidiEvent's in alsa_midi_event.cpp are all AlsaMidiEvent_i's
*/
static VALUE
alsaMidiEventClass_populate(VALUE v_ev, VALUE v_sequencer, VALUE v_midievent)
{
//   fprintf(stderr, "populate\n");
  // 1, get alsa records
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  /*
  // 1b, get AlsaSequencer_i
  VALUE v_seq = rb_ivar_get(v_sequencer, "@handle");
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  */
  // required to locate or construct ports and queues, but maybe the caller should do this?
  // 2, read out snd_seq_event_t and use instance_variable_set on v_midievent
//   fprintf(stderr, "ev.type=%d, evtpnam='%s', CLOCK=%d\n", ev->type, evtypename[ev->type] ? evtypename[ev->type] : "null", SND_SEQ_EVENT_CLOCK);
  if (ev->type < 256 && evtypename[ev->type])
    {
      const char * const nam = evtypename[ev->type]; // enum SYSTEM .. NONE. Each has a specific datatype
//       fprintf(stderr, "using symbol '%s'\n", nam);
      rb_iv_set(v_midievent, "@type", ID2SYM(rb_intern(nam)));
    }
  else
    {
//       fprintf(stderr, "using int\n");
      rb_iv_set(v_midievent, "@type", INT2NUM(ev->type)); // better than nothing
    }
  //rb_iv_set(v_midievent, "@flags", UINT2NUM(ev->flags)); // alsa type flags, not really usefull somehow
  // Because they are UTTERLY undocumented....
  //rb_iv_set(v_midievent, "@tag", UINT2NUM(ev->tag));  WTF....
//   fprintf(stderr, "receiver_queue_id := %d\n", ev->queue);
  rb_iv_set(v_midievent, "@receiver_queue_id", UINT2NUM(ev->queue)); // or @queue_id ?
  static const char *to_zero[] = { "@channel", "@velocity", "@off_velocity", "@duration",
                                   "@param", "@value",
                                   "@time",  // of event!
                                   "@queue_id", // of queue control message
                                   "@connect_sender", "@connect_dest", // for connection events
                                   0 };
  for (const char **s = to_zero; *s; s++)
    rb_iv_set(v_midievent, *s, Qnil);
  if (snd_seq_ev_is_tick(ev))
    rb_iv_set(v_midievent, "@time", UINT2NUM(ev->time.tick));
  else if (snd_seq_ev_is_real(ev))
    rb_iv_set(v_midievent, "@time", rb_ary_new3(2, UINT2NUM(ev->time.time.tv_sec),
                                                   UINT2NUM(ev->time.time.tv_nsec)));
  const ID id_port = rb_intern("port");
  const uint source_client = ev->source.client,
  source_port = ev->source.port,
  dest_client = ev->dest.client,
  dest_port = ev->dest.port;
  rb_iv_set(v_midievent, "@source", rb_funcall(v_sequencer, id_port, 2, UINT2NUM(source_client),
                                               UINT2NUM(source_port)));
  rb_iv_set(v_midievent, "@dest", rb_funcall(v_sequencer, id_port, 2, UINT2NUM(dest_client),
                                             UINT2NUM(dest_port)));
  // 3 data bits
  switch (ev->type)
    {
    case SND_SEQ_EVENT_SYSTEM:
    case SND_SEQ_EVENT_RESULT:
      rb_iv_set(v_midievent, "@param", INT2NUM(ev->data.result.event));
      rb_iv_set(v_midievent, "@value", INT2NUM(ev->data.result.result)); // and not result
      break;
    case SND_SEQ_EVENT_NOTE:
      rb_iv_set(v_midievent, "@off_velocity", UINT2NUM(ev->data.note.off_velocity));
      rb_iv_set(v_midievent, "@duration", UINT2NUM(ev->data.note.duration));
      // fall through
    case SND_SEQ_EVENT_NOTEON:
    case SND_SEQ_EVENT_NOTEOFF:
    case SND_SEQ_EVENT_KEYPRESS:
      get_channel(v_midievent, ev->data.note.channel);
      rb_iv_set(v_midievent, "@value", INT2NUM(ev->data.note.note & 0x7f));
      rb_iv_set(v_midievent, "@velocity", INT2NUM(ev->data.note.velocity & 0x7f));
      break;
    case SND_SEQ_EVENT_CONTROLLER:
      rb_iv_set(v_midievent, "@param", INT2NUM(ev->data.control.param & 0x7f));
      // fall through
    case SND_SEQ_EVENT_PGMCHANGE:
    case SND_SEQ_EVENT_CHANPRESS:
    case SND_SEQ_EVENT_SONGPOS:
    case SND_SEQ_EVENT_SONGSEL:
    case SND_SEQ_EVENT_QFRAME:
    case SND_SEQ_EVENT_TIMESIGN:
    case SND_SEQ_EVENT_KEYSIGN:
      get_channel(v_midievent, ev->data.control.channel);
      rb_iv_set(v_midievent, "@value", INT2NUM(ev->data.control.value & 0x7f));
      break;
    case SND_SEQ_EVENT_REGPARAM:
    case SND_SEQ_EVENT_NONREGPARAM:
      get_channel(v_midievent, ev->data.control.channel);
      rb_iv_set(v_midievent, "@param", INT2NUM(ev->data.control.param));
      rb_iv_set(v_midievent, "@value", INT2NUM(ev->data.control.value));
      break;
    case SND_SEQ_EVENT_CONTROL14:
      get_channel(v_midievent, ev->data.control.channel);
      rb_iv_set(v_midievent, "@param", INT2NUM(ev->data.control.param & 0x7f));
      rb_iv_set(v_midievent, "@value", INT2NUM(ev->data.control.value & 0x7f));
      break;
    case SND_SEQ_EVENT_PITCHBEND:
      get_channel(v_midievent, ev->data.control.channel);
        // rb_iv_set(v_midievent, "@param", INT2NUM(ev->data.control.param & 0x7f)); ????
      rb_iv_set(v_midievent, "@value", INT2NUM(ev->data.control.value));
      break;
    case SND_SEQ_EVENT_SETPOS_TICK:
      rb_iv_set(v_midievent, "@value", UINT2NUM(ev->data.queue.param.time.tick));
      // fall through
    case SND_SEQ_EVENT_START:
    case SND_SEQ_EVENT_CONTINUE:
    case SND_SEQ_EVENT_STOP:
    case SND_SEQ_EVENT_CLOCK:
    case SND_SEQ_EVENT_TICK:
      rb_iv_set(v_midievent, "@queue_id", UINT2NUM(ev->data.queue.queue));
      break;
    case SND_SEQ_EVENT_SETPOS_TIME:
      rb_iv_set(v_midievent, "@queue_id", UINT2NUM(ev->data.queue.queue));
      rb_iv_set(v_midievent, "@value",
                rb_ary_new3(2, UINT2NUM(ev->data.queue.param.time.time.tv_sec),
                            UINT2NUM(ev->data.queue.param.time.time.tv_nsec)));
      break;
    case SND_SEQ_EVENT_SYNC_POS:
      rb_iv_set(v_midievent, "@queue_id", UINT2NUM(ev->data.queue.queue));
      rb_iv_set(v_midievent, "@value", UINT2NUM(ev->data.queue.param.value));
      break;
    case SND_SEQ_EVENT_TEMPO:
      rb_iv_set(v_midievent, "@queue_id", UINT2NUM(ev->data.queue.queue));
      rb_iv_set(v_midievent, "@value", INT2NUM(ev->data.queue.param.value));
      break;
    case SND_SEQ_EVENT_QUEUE_SKEW:
      rb_iv_set(v_midievent, "@queue_id", UINT2NUM(ev->data.queue.queue));
      rb_iv_set(v_midievent, "@value", rb_ary_new3(2, UINT2NUM(ev->data.queue.param.skew.value),
                                                  UINT2NUM(ev->data.queue.param.skew.base)));
      break;
    case SND_SEQ_EVENT_TUNE_REQUEST:
    case SND_SEQ_EVENT_RESET:
    case SND_SEQ_EVENT_SENSING:
    case SND_SEQ_EVENT_ECHO:
    case SND_SEQ_EVENT_OSS:
    case SND_SEQ_EVENT_NONE:
      break;
    case SND_SEQ_EVENT_PORT_START:
    case SND_SEQ_EVENT_PORT_EXIT:
    case SND_SEQ_EVENT_PORT_CHANGE:
      rb_iv_set(v_midievent, "@value",
                rb_funcall(v_sequencer, id_port, 2,
                           UINT2NUM(ev->data.addr.client),
                           UINT2NUM(ev->data.addr.port)));
      // fall through  ( do we need client? could call both value as well? )
      // could always call port.client, not ?
      break;
    case SND_SEQ_EVENT_CLIENT_START:
    case SND_SEQ_EVENT_CLIENT_EXIT:
    case SND_SEQ_EVENT_CLIENT_CHANGE:
      {
        const ID id_clients = rb_intern("id_clients");
        VALUE v_clients = rb_funcall(v_sequencer, id_clients, 0);
        rb_iv_set(v_midievent, "@value", rb_hash_aref(v_clients, UINT2NUM(ev->data.addr.client)));
        break;
      }
    case SND_SEQ_EVENT_PORT_SUBSCRIBED:
    case SND_SEQ_EVENT_PORT_UNSUBSCRIBED:
      rb_iv_set(v_midievent, "@connect_sender",
                rb_funcall(v_sequencer, id_port, 2,
                           UINT2NUM(ev->data.connect.sender.client),
                           UINT2NUM(ev->data.connect.sender.port)));
      rb_iv_set(v_midievent, "@connect_dest",
                           rb_funcall(v_sequencer, id_port, 2,
                                      UINT2NUM(ev->data.connect.dest.client),
                                      UINT2NUM(ev->data.connect.dest.port)));
      break;
    case SND_SEQ_EVENT_USR0:
    case SND_SEQ_EVENT_USR1:
    case SND_SEQ_EVENT_USR2:
    case SND_SEQ_EVENT_USR3:
    case SND_SEQ_EVENT_USR4:
    case SND_SEQ_EVENT_USR5:
    case SND_SEQ_EVENT_USR6:
    case SND_SEQ_EVENT_USR7:
    case SND_SEQ_EVENT_USR8:
    case SND_SEQ_EVENT_USR9:
      // ?????
      break;
    case SND_SEQ_EVENT_SYSEX:
    case SND_SEQ_EVENT_BOUNCE:
    case SND_SEQ_EVENT_USR_VAR0:
    case SND_SEQ_EVENT_USR_VAR1:
    case SND_SEQ_EVENT_USR_VAR2:
    case SND_SEQ_EVENT_USR_VAR3:
    case SND_SEQ_EVENT_USR_VAR4:
      {
        VALUE v_ext = rb_str_new((const char *)ev->data.ext.ptr, ev->data.ext.len);
        rb_funcall(v_ext, rb_intern("force_encoding"), 1, rb_str_new2("ascii-8bit"));
        rb_iv_set(v_midievent, "@value", v_ext);
        break;
      }
    default:
      RAISE_MIDI_ERROR_FMT1("unhandled event %d", ev->type);
      break;
    }
  return Qnil;
}

void
alsa_midi_plusplus_init()
{
  rb_define_method(alsaMidiEventClass, "populate", RUBY_METHOD_FUNC(alsaMidiEventClass_populate), 2);
  for (unsigned i = 0; i < 256; i++)
    evtypename[i] = 0;
  evtypename[SND_SEQ_EVENT_SYSTEM] = "system";
  evtypename[SND_SEQ_EVENT_RESULT] = "result";
  evtypename[SND_SEQ_EVENT_NOTE] = "note";
  evtypename[SND_SEQ_EVENT_NOTEON] = "noteon";
  evtypename[SND_SEQ_EVENT_NOTEOFF] = "noteoff";
  evtypename[SND_SEQ_EVENT_KEYPRESS] = "keypress";
  evtypename[SND_SEQ_EVENT_CONTROLLER] = "controller";
  evtypename[SND_SEQ_EVENT_PGMCHANGE] = "pgmchange";
  evtypename[SND_SEQ_EVENT_CHANPRESS] = "chanpress";
  evtypename[SND_SEQ_EVENT_PITCHBEND] = "pitchbend";
  evtypename[SND_SEQ_EVENT_CONTROL14] = "control14";
  evtypename[SND_SEQ_EVENT_NONREGPARAM] = "nonregparam";
  evtypename[SND_SEQ_EVENT_REGPARAM] = "regparam";
  evtypename[SND_SEQ_EVENT_SONGPOS] = "songpos";
  evtypename[SND_SEQ_EVENT_SONGSEL] = "songsel";
  evtypename[SND_SEQ_EVENT_QFRAME] = "qframe";
  evtypename[SND_SEQ_EVENT_TIMESIGN] = "timesign";
  evtypename[SND_SEQ_EVENT_KEYSIGN] = "keysign";
  evtypename[SND_SEQ_EVENT_SETPOS_TICK] = "setpos_tick";
  evtypename[SND_SEQ_EVENT_SETPOS_TIME] = "setpos_time";
  evtypename[SND_SEQ_EVENT_START] = "start";
  evtypename[SND_SEQ_EVENT_CONTINUE] = "continue";
  evtypename[SND_SEQ_EVENT_STOP] = "stop";
  evtypename[SND_SEQ_EVENT_CLOCK] = "clock";
  evtypename[SND_SEQ_EVENT_TICK] = "tick";
  evtypename[SND_SEQ_EVENT_SYNC_POS] = "sync_pos";
  evtypename[SND_SEQ_EVENT_TEMPO] = "tempo";
  evtypename[SND_SEQ_EVENT_QUEUE_SKEW] = "queue_skew";
  evtypename[SND_SEQ_EVENT_TUNE_REQUEST] = "tune_request";
  evtypename[SND_SEQ_EVENT_RESET] = "reset";
  evtypename[SND_SEQ_EVENT_SENSING] = "sensing";
  evtypename[SND_SEQ_EVENT_ECHO] = "echo";
  evtypename[SND_SEQ_EVENT_OSS] = "oss";
  evtypename[SND_SEQ_EVENT_NONE] = "none";
  evtypename[SND_SEQ_EVENT_PORT_START] = "port_start";
  evtypename[SND_SEQ_EVENT_PORT_EXIT] = "port_exit";
  evtypename[SND_SEQ_EVENT_PORT_CHANGE] = "port_change";
  evtypename[SND_SEQ_EVENT_CLIENT_START] = "client_start";
  evtypename[SND_SEQ_EVENT_CLIENT_EXIT] = "client_exit";
  evtypename[SND_SEQ_EVENT_CLIENT_CHANGE] = "client_change";
  evtypename[SND_SEQ_EVENT_PORT_SUBSCRIBED] = "port_subscribed";
  evtypename[SND_SEQ_EVENT_PORT_UNSUBSCRIBED] = "port_unsubscribed";
  evtypename[SND_SEQ_EVENT_USR0] = "usr0";
  evtypename[SND_SEQ_EVENT_USR1] = "usr1";
  evtypename[SND_SEQ_EVENT_USR2] = "usr2";
  evtypename[SND_SEQ_EVENT_USR3] = "usr3";
  evtypename[SND_SEQ_EVENT_USR4] = "usr4";
  evtypename[SND_SEQ_EVENT_USR5] = "usr5";
  evtypename[SND_SEQ_EVENT_USR6] = "usr6";
  evtypename[SND_SEQ_EVENT_USR7] = "usr7";
  evtypename[SND_SEQ_EVENT_USR8] = "usr8";
  evtypename[SND_SEQ_EVENT_USR9] = "usr9";
  evtypename[SND_SEQ_EVENT_SYSEX] = "sysex";
  evtypename[SND_SEQ_EVENT_BOUNCE] = "bounce";
  evtypename[SND_SEQ_EVENT_USR_VAR0] = "usr_var0";
  evtypename[SND_SEQ_EVENT_USR_VAR1] = "usr_var1";
  evtypename[SND_SEQ_EVENT_USR_VAR2] = "usr_var2";
  evtypename[SND_SEQ_EVENT_USR_VAR3] = "usr_var3";
  evtypename[SND_SEQ_EVENT_USR_VAR4] = "usr_var4";
}

