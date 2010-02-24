
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

#if defined(DUMP_API)
#define DUMP_STREAM stderr
#endif

#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaDriver, alsaMidiError;

// returns a AlsaSequencer_i
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
  if (r) RAISE_MIDI_ERROR(r);
  return Data_Wrap_Struct(alsaSequencerClass, 0, 0, seq);
}

/*
int snd_seq_open        (       snd_seq_t **     seqp,
                const char *    name,
                int     streams,
                int     mode
        )

Open the ALSA sequencer.

Parameters:
        seqp    Pointer to a snd_seq_t pointer. This pointer must be kept and passed to most of the other sequencer functions.
        name    The sequencer's "name". This is not a name you make up for your own purposes; it has special significance to the ALSA library. Usually you need to pass "default" here.
        streams         The read/write mode of the sequencer. Can be one of three values:

        * SND_SEQ_OPEN_OUTPUT - open the sequencer for output only
        * SND_SEQ_OPEN_INPUT - open the sequencer for input only
        * SND_SEQ_OPEN_DUPLEX - open the sequencer for output and input

Note:
    Internally, these are translated to O_WRONLY, O_RDONLY and O_RDWR respectively and used as the second argument to the C library open() call.

Parameters:
        mode    Optional modifier. Can be either 0, or SND_SEQ_NONBLOCK, which will make read/write operations non-blocking. This can also be set later using snd_seq_nonblock().

Returns:
    0 on success otherwise a negative error code

Creates a new handle and opens a connection to the kernel sequencer interface. After a client is created successfully, an event with SND_SEQ_EVENT_CLIENT_START is broadcast to announce port.

See also:
    snd_seq_open_lconf(), snd_seq_close(), snd_seq_type(), snd_seq_name(), snd_seq_nonblock(), snd_seq_client_id()
*/


// returns a negative errorcode (int) or else a AlsaClientInfo_i instance
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
  int r = snd_seq_client_info_malloc(&m);
  return r ? INT2NUM(r) : Data_Wrap_Struct(alsaClientInfoClass, 0/*mark*/, snd_seq_client_info_free/*free*/, m);
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
  int r = snd_seq_queue_info_malloc(&m);
  return r ? INT2NUM(r) : Data_Wrap_Struct(alsaQueueInfoClass, 0/*mark*/, snd_seq_queue_info_free/*free*/, m);
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
  return r ? INT2NUM(r) : Data_Wrap_Struct(alsaPortInfoClass, 0/*mark*/, snd_seq_port_info_free, m);
}

static VALUE
wrap_snd_seq_queue_tempo_malloc(VALUE v_module)
{
  snd_seq_queue_tempo_t *m = 0;
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_queue_tempo_malloc(null)\n");
#endif
  int r = snd_seq_queue_tempo_malloc(&m);
  return r ? INT2NUM(r) : Data_Wrap_Struct(alsaQueueTempoClass, 0/*mark*/, snd_seq_queue_tempo_free/*free*/, m);
}

static VALUE
wrap_snd_seq_queue_status_malloc(VALUE v_module)
{
  snd_seq_queue_status_t *m = 0;
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_queue_status_malloc(null)\n");
#endif
  int r = snd_seq_queue_status_malloc(&m);
  return r ? INT2NUM(r) : Data_Wrap_Struct(alsaQueueStatusClass, 0/*mark*/, snd_seq_queue_status_free/*free*/, m);
}

static VALUE
wrap_snd_seq_port_subscribe_malloc(VALUE v_mod)
{
  snd_seq_port_subscribe_t *m = 0;
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_port_subscribe_malloc(null)\n");
#endif
  int r = snd_seq_port_subscribe_malloc(&m);
  return r ? INT2NUM(r) : Data_Wrap_Struct(alsaPortSubscriptionClass, 0/*mark*/, snd_seq_port_subscribe_free/*free*/, m);
}

static VALUE
wrap_snd_strerror(VALUE v_module, VALUE v_err)
{
//   fprintf(stderr, "snd_strerror(%d) -> %s\n", NUM2INT(v_err), snd_strerror(NUM2INT(v_err)));
  return rb_str_new2(snd_strerror(NUM2INT(v_err)));
}

extern "C" void
Init_alsa_midi()
{
  VALUE rttsModule = rb_define_module("RRTS");
  alsaDriver = rb_define_module_under(rttsModule, "Driver");
  alsaMidiError = rb_define_class_under(rttsModule, "AlsaMidiError", rb_eStandardError);
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
  rb_define_module_function(alsaDriver, "ev_malloc", RUBY_METHOD_FUNC(ev_malloc), 0);
  rb_define_module_function(alsaDriver, "snd_strerror", RUBY_METHOD_FUNC(wrap_snd_strerror), 1);

  alsa_seq_init();
  alsa_midi_queue_init();
  alsa_midi_client_init();
  alsa_midi_event_init();
  alsa_midi_port_init();
  port_subscription_init();
  alsa_midi_plusplus_init();
}
