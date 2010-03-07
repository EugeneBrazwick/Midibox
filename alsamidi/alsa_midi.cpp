
// If changed do:         make
// To create Makefile:    ruby ./extruby.rb

// #define DUMP_API

#pragma implementation
#include "alsa_midi.h"
#include "alsa_seq.h"
#include "alsa_midi_event.h"
#include "alsa_midi_queue.h"
#include "alsa_midi_client.h"
#include "alsa_midi_port.h"
#include "alsa_midi++.h"
#include "alsa_port_subscription.h"
#include "alsa_remove.h"
#include "alsa_client_pool.h"

#if defined(DUMP_API)
#define DUMP_STREAM stderr
#endif

#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaDriver, alsaMidiError;

/*
AlsaSequencer_i snd_seq_open [name = 'default [, streams = SND_SEQ_OPEN_DUPLEX [, mode = 0]]]

Open the ALSA sequencer.

Parameters:
      name    The sequencer's "name". This is not a name you make up for your own purposes;
              it has special significance to the ALSA library.
              Usually you need to pass "default" here.
      streams         The read/write mode of the sequencer. Can be one of three values:

      * SND_SEQ_OPEN_OUTPUT - open the sequencer for output only
      * SND_SEQ_OPEN_INPUT - open the sequencer for input only
      * SND_SEQ_OPEN_DUPLEX - open the sequencer for output and input

      Note:
      Internally, these are translated to O_WRONLY, O_RDONLY and O_RDWR respectively and used
      as the second argument to the C library open() call.

      mode: Optional modifier. Can be either 0, or else SND_SEQ_NONBLOCK, which will make
           read/write operations non-blocking. This can also be set later using snd_seq_nonblock().
           The default is blocking mode.

Returns:
  A AlsaSequencer_i instance. This instance must be kept and passed to most of
  the other sequencer functions.

Creates a new handle and opens a connection to the kernel sequencer interface.
After a client is created successfully, an event with SND_SEQ_EVENT_CLIENT_START
is broadcast to announce port.
*/
static VALUE
wrap_snd_seq_open(int argc, VALUE *v_params, VALUE v_alsamod)
{
  VALUE v_name, v_streams, v_mode;
  rb_scan_args(argc, v_params, "03", &v_name, &v_streams, &v_mode);
  const char *const name = NIL_P(v_name) ? "default" : StringValuePtr(v_name);
  const int streams = NIL_P(v_streams) ? SND_SEQ_OPEN_DUPLEX : NUM2INT(v_streams);
  const int mode = NIL_P(v_mode) ? 0 /*blocking mode*/ : BOOL2INT(v_mode);
  snd_seq_t * seq = 0;
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_open(null, %s, %d, %d)\n", name, streams, mode);
#endif
  const int r = snd_seq_open(&seq, name, streams, mode);
  if (r) RAISE_MIDI_ERROR("opening sequencer", r);
  return Data_Wrap_Struct(alsaSequencerClass, 0, 0, seq);
}

// returns AlsaClientInfo_i instance
/* Since we really don't know when the ruby object is no longer used, we cannot
use explicit free!
This also gives extreme problems with the use of next_client or next_port since
these basicly 'overwrite' the contents, but they may be stored in a ruby array
which causes weird behaviour!
*/
static VALUE
wrap_snd_seq_client_info_malloc(VALUE v_module)
{
  snd_seq_client_info_t *m = 0;
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_client_info_malloc(null)\n");
#endif
  const int r = snd_seq_client_info_malloc(&m);
  if (r < 0) RAISE_MIDI_ERROR("allocating client_info", r);
  return Data_Wrap_Struct(alsaClientInfoClass, 0/*mark*/, snd_seq_client_info_free/*free*/, m);
}

static VALUE
ev_malloc(VALUE v_module)
{
  return Data_Wrap_Struct(alsaMidiEventClass, 0/*mark*/, free/*free*/, ALLOC(snd_seq_event_t));
}

static VALUE
wrap_snd_seq_queue_info_malloc(VALUE v_module)
{
  snd_seq_queue_info_t *m = 0;
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_queue_info_malloc(null)\n");
#endif
  const int r = snd_seq_queue_info_malloc(&m);
  if (r < 0) RAISE_MIDI_ERROR("allocating queue_info", r);
  return Data_Wrap_Struct(alsaQueueInfoClass, 0/*mark*/, snd_seq_queue_info_free/*free*/, m);
}


/*
int snd_seq_client_info_malloc          (       snd_seq_client_info_t **         ptr     )

allocate an empty snd_seq_client_info_t using standard malloc

Parameters:
        ptr     returned pointer

Returns:
    0 on success otherwise negative error code
*/

static VALUE
wrap_snd_seq_port_info_malloc(VALUE v_module)
{
  snd_seq_port_info_t *m = 0;
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_port_info_malloc(null)\n");
#endif
  const int r = snd_seq_port_info_malloc(&m);
  if (r < 0) RAISE_MIDI_ERROR("allocating port_info", r);
  return Data_Wrap_Struct(alsaPortInfoClass, 0/*mark*/, snd_seq_port_info_free, m);
}

/* AlsaQueueTempo_i snd_seq_queue_tempo_malloc. Not required since done automatically
  by AlsaQueue_i.tempo
*/
static VALUE
wrap_snd_seq_queue_tempo_malloc(VALUE v_module)
{
  snd_seq_queue_tempo_t *m = 0;
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_queue_tempo_malloc(null)\n");
#endif
  const int r = snd_seq_queue_tempo_malloc(&m);
  if (r < 0) RAISE_MIDI_ERROR("allocating queue_tempo", r);
  return Data_Wrap_Struct(alsaQueueTempoClass, 0/*mark*/, snd_seq_queue_tempo_free/*free*/, m);
}

/* AlsaQueueStatus_i snd_seq_queue_tempo_malloc. Not required since done automatically
 by AlsaQueue_i.status
*/
static VALUE
wrap_snd_seq_queue_status_malloc(VALUE v_module)
{
  snd_seq_queue_status_t *m = 0;
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_queue_status_malloc(null)\n");
#endif
  const int r = snd_seq_queue_status_malloc(&m);
  if (r < 0) RAISE_MIDI_ERROR("allocating queue_status", r);
  return Data_Wrap_Struct(alsaQueueStatusClass, 0/*mark*/, snd_seq_queue_status_free/*free*/, m);
}

/* AlsaPortSubscription_i snd_seq_port_subscribe_malloc.
*/
static VALUE
wrap_snd_seq_port_subscribe_malloc(VALUE v_mod)
{
  snd_seq_port_subscribe_t *m = 0;
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_port_subscribe_malloc(null)\n");
#endif
  const int r = snd_seq_port_subscribe_malloc(&m);
  if (r < 0) RAISE_MIDI_ERROR("allocating port_subscribe", r);
  return Data_Wrap_Struct(alsaPortSubscriptionClass, 0/*mark*/, snd_seq_port_subscribe_free/*free*/, m);
}

/* AlsaRemoveEvents_i snd_seq_remove_events_malloc.
*/
static VALUE
wrap_snd_seq_remove_events_malloc(VALUE v_mod)
{
  snd_seq_remove_events_t *m = 0;
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_remove_events_malloc(null)\n");
#endif
  const int r = snd_seq_remove_events_malloc(&m);
  if (r < 0) RAISE_MIDI_ERROR("allocating remove_events", r);
  return Data_Wrap_Struct(alsaRemoveEventsClass, 0/*mark*/, snd_seq_remove_events_free/*free*/, m);
}

/* AlsaClientPool_i snd_seq_client_pool_malloc.
*/
static VALUE
wrap_snd_seq_client_pool_malloc(VALUE v_mod)
{
  snd_seq_client_pool_t *m = 0;
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_client_pool_malloc(null)\n");
#endif
  const int r = snd_seq_client_pool_malloc(&m);
  if (r < 0) RAISE_MIDI_ERROR("allocating client_pool", r);
  return Data_Wrap_Struct(alsaClientPoolClass, 0/*mark*/, snd_seq_client_pool_free/*free*/, m);
}

static VALUE
wrap_snd_strerror(VALUE v_module, VALUE v_err)
{
//   fprintf(stderr, "snd_strerror(%d) -> %s\n", NUM2INT(v_err), snd_strerror(NUM2INT(v_err)));
  return rb_str_new2(snd_strerror(NUM2INT(v_err)));
}

VALUE param2sym(uint param)
{
  static const char *paramname[128] = {
    "bank", "modwheel", "breath", 0, "foot",
    "portamento_time", "data_entry", "volume", "balance", 0,
    // 10
    "pan", "expression", "effect1", "effect2", 0,
    0, "general_purpose1", "general_purpose2", "general_purpose3", "general_purpose4",
    // 20
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0,
    // 30
    0, 0, "bank_lsb", "modwheel_lsb", "breath_lsb",
    0, "foot_lsb", "portamento_time_lsb", "data_entry_lsb", "main_volume_lsb",
    // 40
    "balance_lsb", 0, "pan_lsb", "expression_lsb", "effect1_lsb",
    "effect2_lsb", 0, 0, "general_purpose1_lsb", "general_purpose2_lsb",
    // 50
    "general_purpose3_lsb", "general_purpose4_lsb", 0, 0, 0,
    0, 0, 0, 0, 0,
    // 60
    0, 0, 0, 0, "sustain",
    "portamento", "sostenuto", "soft", "legato", "hold2",
    // 70
    "sound_variation", "timbre", "release", "attack", "brightness",
    "sc6", "sc7", "sc8", "sc9", "sc10",
    // 80 (0x50)
    "general_purpose5", "general_purpose6", "general_purpose7", "general_purpose8", "portamento_control",
     0, 0, 0, 0, 0,
     // 90
     0, "reverb", "tremolo", "chorus", "detune",
     "phaser", "data_increment", "data_decrement", "nonreg_parm_num_lsb", "nonreg_parm_num",
     // 100 (0x64)
     "regist_parm_num_lsb", "regist_parm_num", 0, 0, 0,
     0, 0, 0, 0, 0,
     // 110 (0x6d)
     0, 0, 0, 0, 0,
     0, 0, 0, 0, 0,
     // 120 (0x78)
     "all_sounds_off", "reset_controllers", "local_control_switch", "all_notes_pff", "omni_off",
     "omni_on", "mono", "poly" // ?
  };
  const char *const parmname = paramname[param];
  if (parmname)
    return ID2SYM(rb_intern(parmname));
  return INT2NUM(param);
}

static VALUE
param2sym_v(VALUE v_module, VALUE v_param)
{
  if (FIXNUM_P(v_param))
    return param2sym(NUM2UINT(v_param));
  return v_param; // asume it is already a symbol then
}

extern "C" void
Init_alsa_midi()
{
  VALUE rrtsModule = rb_define_module("RRTS");
  alsaDriver = rb_define_module_under(rrtsModule, "Driver");
  alsaMidiError = rb_define_class_under(rrtsModule, "AlsaMidiError", rb_eStandardError);
  // class to store the result of snd_seq_port_subscribe_malloc: a snd_seq_port_subscribe_t*
  // alsaPortClass = rb_define_class_under(alsaDriver, "AlsaPort_i", rb_cObject);
  rb_define_module_function(alsaDriver, "snd_seq_open", RUBY_METHOD_FUNC(wrap_snd_seq_open), -1);

  // since snd_seq_open is here
  WRAP_CONSTANT(SND_SEQ_OPEN_OUTPUT); // open the sequencer for output only
  WRAP_CONSTANT(SND_SEQ_OPEN_INPUT); //- open the sequencer for input only
  WRAP_CONSTANT(SND_SEQ_OPEN_DUPLEX); // - open the sequencer for output and input
  WRAP_CONSTANT(SND_SEQ_NONBLOCK); // - open the sequencer in non-blocking mode

  // all freed automatically.
  rb_define_module_function(alsaDriver, "snd_seq_client_info_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_client_info_malloc), 0);
  rb_define_module_function(alsaDriver, "snd_seq_port_info_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_malloc), 0);
  rb_define_module_function(alsaDriver, "snd_seq_queue_info_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_malloc), 0);
  rb_define_module_function(alsaDriver, "snd_seq_queue_tempo_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_malloc), 0);
  rb_define_module_function(alsaDriver, "snd_seq_queue_status_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_malloc), 0);
  // the snd_seq_port_subscribe_free is called automatically.
  rb_define_module_function(alsaDriver, "snd_seq_port_subscribe_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_malloc), 0);
  rb_define_module_function(alsaDriver, "snd_seq_remove_events_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_malloc), 0);
  rb_define_module_function(alsaDriver, "snd_seq_client_pool_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_client_pool_malloc), 0);
  rb_define_module_function(alsaDriver, "ev_malloc", RUBY_METHOD_FUNC(ev_malloc), 0);
  rb_define_module_function(alsaDriver, "param2sym", RUBY_METHOD_FUNC(param2sym_v), 1);
  rb_define_module_function(alsaDriver, "snd_strerror", RUBY_METHOD_FUNC(wrap_snd_strerror), 1);

  alsa_seq_init();
  alsa_midi_queue_init();
  alsa_midi_client_init();
  alsa_midi_event_init();
  alsa_midi_port_init();
  port_subscription_init();
  alsa_remove_init();
  alsa_client_pool_init();
  alsa_midi_plusplus_init();
}
