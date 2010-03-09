
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
#include "alsa_system_info.h"

#if defined(DUMP_API)
#define DUMP_STREAM stderr
#endif

#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaDriver, alsaMidiError;

/* AlsaSequencer_i Driver#seq_open [name = 'default [, streams = SND_SEQ_OPEN_DUPLEX [, mode = 0]]]

Open the ALSA sequencer.

Parameters:
      [name]    The sequencer's "name". This is not a name you make up for your own purposes;
                it has special significance to the ALSA library.
                Usually you need to pass "default" here.
      [streams] The read/write mode of the sequencer. Can be one of three values:

          * SND_SEQ_OPEN_OUTPUT - open the sequencer for output only
          * SND_SEQ_OPEN_INPUT - open the sequencer for input only
          * SND_SEQ_OPEN_DUPLEX - open the sequencer for output and input

          Note:
          Internally, these are translated to O_WRONLY, O_RDONLY and O_RDWR respectively and used
          as the second argument to the C library open() call.

       [mode] Optional modifier. Can be either 0, or else SND_SEQ_NONBLOCK, which will make
              read/write operations non-blocking. This can also be set later using
              AlsaSequencer_i#nonblock.
              The default is blocking mode.

Returns:
  A AlsaSequencer_i instance. This instance must be kept and passed to most of
  the other sequencer functions.

Creates a new handle and opens a connection to the kernel sequencer interface.
After a client is created successfully, an event with SND_SEQ_EVENT_CLIENT_START
is broadcast to announce port.

See also AlsaSequencer_i#close.
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

/* AlsaClientInfo_i Driver#client_info_malloc

The returned instance is automatically freed when the object goes out of scope.
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

/* AlsaSystemInfo_i system_info_malloc

Returns: a new AlsaSystemInfo_i instance which is automatically freed
*/
static VALUE wrap_snd_seq_system_info_malloc(VALUE v_module)
{
  snd_seq_system_info_t *m = 0;
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_system_info_malloc(null)\n");
#endif
  const int r = snd_seq_system_info_malloc(&m);
  if (r < 0) RAISE_MIDI_ERROR("allocating system_info", r);
  return Data_Wrap_Struct(alsaSystemInfoClass, 0/*mark*/, snd_seq_system_info_free/*free*/, m);
}

/* AlsaMidiEvent_i Driver#ev_malloc
Returns: a new AlsaMidiEvent_i instance, which is automatically freed. The buffer comes
back uninitialized so you may want to call AlsaMidiEvent_i#clear first.

This has no counterpart in the alsa API, since one would never (have to) do this.
*/
static VALUE
ev_malloc(VALUE v_module)
{
  return Data_Wrap_Struct(alsaMidiEventClass, 0/*mark*/, free/*free*/, ALLOC(snd_seq_event_t));
}

/* AlsaQueueInfo_i queue_info_malloc
Allocates a new queue_info structure which is automatically freed when the instance
goes out of scope
*/
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


/* AlsaPortInfo_i port_info_malloc

allocate an empty snd_seq_port_info_t using standard malloc

Returns:
    the port_info, it will automatically be freed
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

/* AlsaQueueTempo_i queue_tempo_malloc
  Not required since done automatically called by AlsaQueue_i#tempo, if no parameter is passed
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

/* AlsaQueueStatus_i queue_tempo_malloc. Not required since done automatically
 called internally by AlsaQueue_i#status if no parameter is passed
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

/* AlsaPortSubscription_i port_subscribe_malloc
Returns: a new port_subscribe structure which will be freed automatically
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

/* :rdoc: AlsaRemoveEvents_i remove_events_malloc
Returns a new remove_events structure, which is freed automatically
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

/* :rdoc: AlsaClientPool_i client_pool_malloc
Allocates a new client_pool structure, which is automatically freed
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

/* string strerror errno
Returns the errorstring for the given systemerror, or alsa error.
*/
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

/* [clientid, portid] parse_address(arg)
parse the given string and get the sequencer address

Parameters:
[arg] the string to be parsed

Returns clientid + portid on success or it raises a AlsaMidiError.

This function parses the sequencer client and port numbers from the given string.
The client and port tokes are separated by either colon or period, e.g. 128:1.
The function accepts also a client name not only digit numbers.

The arguments could be '20:2' or 'MIDI2:0' etc.  Portnames are not understood!

See AlsaSequencer_i#parse_address
*/
static VALUE
wrap_snd_seq_parse_address(VALUE v_module, VALUE v_arg)
{
  snd_seq_addr_t ret;
  const char *const arg = StringValuePtr(v_arg);
  const int r = snd_seq_parse_address(0, &ret, arg);
  if (r < 0) RAISE_MIDI_ERROR_FMT2("Invalid port '%s' - %s", arg, snd_strerror(r));
  return rb_ary_new3(2, INT2NUM(ret.client), INT2NUM(ret.port));
}

/* symbol param2sym param
If the passed parameter is an integer, return the accompanying symbol, which is
the symbol of the 'param' event attribute, used for ControllerEvent.
Otherwise, return param as is.
Example:
    Driver::param2sym(0) -> :bank
*/
static VALUE
param2sym_v(VALUE v_module, VALUE v_param)
{
  if (FIXNUM_P(v_param))
    return param2sym(NUM2UINT(v_param));
  return v_param; // asume it is already a symbol then
}

/* RRTS
This is the main namespace. Ruby RealTime Sequencer. But how RT can it be?
Currently it contains the Alsa (Advanced Linux Sound Architecture) MIDI Driver
plus supporter classes, in particular Sequencer.

The following rules were used:

  - This is a literal implementation of the almost full alsa snd_seq API

  - functions have been made methods by using arg0 as self.

  - the snd_seq_ prefix was removed for methods, but not for constants.

  - special case seq_open for snd_seq_open, since just 'open' would conflict with
    Kernel#open

  - the support classes have methods that do not require the Alsa constants anymore

  - obvious defaults value for parameters are applied, whereas the original API is C,
    which has no defaults

  - where values are often used as pairs (or even a c-struct) as in client+port=address
   I allow passing the address as a tuple (array with elements at 0 and 1).

  - similarly, instances of the Driver classes can be used, or even the higher level
  classes (not always) where the original API expects the id or handle to be passed.
  This is always the case for queueids, where AlsaMidiQueue_i can be used, or for portids
  where AlsaMidiPort_i can be used.

  - methods starting with set (snd_seq_..._set), and with a single (required) argument have been
    replaced by the equivalent setter in ruby (as 'port=')

  - set methods with 0 or 2 or more arguments still remain

  - for methods starting with get_ this prefix has been removed as well.

  - getters that return a boolean are suffixed with '?'.

  - errors became exceptions, in particular AlsaMidiError and ENOSPC somewhere.
   Exceptions on this rule are methods used in finalizers, since exceptions in finalizers
   are really not funny. So close/free/clear or whatever return their original value.
   Currently now errormessage is printed, but I may change this in the future. This depends
   on the failchance of given methods.

  - integers that could be (or should be) interpreted as booleans have been replaced by booleans

  - methods with a return argumentaddress in C have this method now return this parameter.
  In some cases this lead to returning a tuple.

  - methods that would always return nil (though the original may not) now return self

  - in some cases, some parameters became meaningless.

  - normally in C, you would operate on the event object direct, using the structure definition.
   This is no longer possible, and where names where unique within the union the fieldname became
   a setter, getter. For ambiguous situations, the same approach is chosen, but the backend uses
   the type as set in the event.
   So:
     ev = ev_malloc
     ev.channel = 7
   is wrong as the type is not yet set and we must choose between ev.data.note.channel or
   ev.data.control.channel.
   But:
     ev = ev_malloc
     ev.note = 63
   is perfectly OK, since the +note+ selector is unambiguous (ev.data.note.note).

  - in some cases, alsa uses ambigues names. Example the macro snd_seq_ev_set_source only sets
   the port, and not the client. ev.source.port = p.
   This has been renamed to source_port, similarly source_client source, and the three setters are
   included. However for 'queue' this would not work, so
   ev.queue refers to the queue on which the event was send or received while
   ev.queue_queue refers to the queue as a subject of a queue control event

  - all other queue params have a queue_ prefix, including value.  ev.value is the control value.
   Example: ev.data.queue.param.value  should be replaced with ev.queue_value.

*IMPORTANT*: using this API as is, will not be the most efficient way to deal with
alsa_midi.so.  Please use the ruby classes and additional methods in this library.
See alsa_midi++.cpp
This yields in particular for the MidiEvent API since the only way to write or read
a field is through a wrapped method. Even more, the C API has a lot of macros that
are now implemented as ruby methods. Again, this is not efficient.
However, it implies that existing programs can easily be ported, see for instance
rrecordmidi.rb which is a 1 on 1 port of arecordmidi.c.
Same for rplaymidi.rb

The revents method is rather vague and the examples do not use it. What is the timeout?
Or isn't there any.  Anyway, the result is made consistent with that of poll.
*/
extern "C" void
Init_alsa_midi()
{
  VALUE rrtsModule = rb_define_module("RRTS");
  /* Driver is the namespace module for all things Alsa and MIDI
  */
  alsaDriver = rb_define_module_under(rrtsModule, "Driver");
  /* AlsaMidiError is an exception class that inherits from StandardError.
  It is used for all Driver errors.
  */
  alsaMidiError = rb_define_class_under(rrtsModule, "AlsaMidiError", rb_eStandardError);
  // class to store the result of snd_seq_port_subscribe_malloc: a snd_seq_port_subscribe_t*
  // alsaPortClass = rb_define_class_under(alsaDriver, "AlsaPort_i", rb_cObject);
  rb_define_module_function(alsaDriver, "seq_open", RUBY_METHOD_FUNC(wrap_snd_seq_open), -1);

  // since snd_seq_open is here
  WRAP_CONSTANT(SND_SEQ_OPEN_OUTPUT); // open the sequencer for output only
  WRAP_CONSTANT(SND_SEQ_OPEN_INPUT); //- open the sequencer for input only
  WRAP_CONSTANT(SND_SEQ_OPEN_DUPLEX); // - open the sequencer for output and input
  WRAP_CONSTANT(SND_SEQ_NONBLOCK); // - open the sequencer in non-blocking mode

  // all freed automatically.
  rb_define_module_function(alsaDriver, "client_info_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_client_info_malloc), 0);
  rb_define_module_function(alsaDriver, "port_info_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_malloc), 0);
  rb_define_module_function(alsaDriver, "queue_info_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_malloc), 0);
  rb_define_module_function(alsaDriver, "queue_tempo_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_malloc), 0);
  rb_define_module_function(alsaDriver, "queue_status_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_malloc), 0);
  // the snd_seq_port_subscribe_free is called automatically.
  rb_define_module_function(alsaDriver, "port_subscribe_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_malloc), 0);
  rb_define_module_function(alsaDriver, "remove_events_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_malloc), 0);
  rb_define_module_function(alsaDriver, "client_pool_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_client_pool_malloc), 0);
  rb_define_module_function(alsaDriver, "system_info_malloc", RUBY_METHOD_FUNC(wrap_snd_seq_system_info_malloc), 0);
  rb_define_module_function(alsaDriver, "ev_malloc", RUBY_METHOD_FUNC(ev_malloc), 0);
  rb_define_module_function(alsaDriver, "param2sym", RUBY_METHOD_FUNC(param2sym_v), 1);
  rb_define_module_function(alsaDriver, "strerror", RUBY_METHOD_FUNC(wrap_snd_strerror), 1);
  rb_define_module_function(alsaDriver, "parse_address", RUBY_METHOD_FUNC(wrap_snd_seq_parse_address), 1);

  alsaPortSubscriptionClass = rb_define_class_under(alsaDriver, "AlsaPortSubscription_i", rb_cObject);
  alsaClientInfoClass = rb_define_class_under(alsaDriver, "AlsaClientInfo_i", rb_cObject);
  alsaClientPoolClass = rb_define_class_under(alsaDriver, "AlsaClientPool_i", rb_cObject);
  alsaRemoveEventsClass = rb_define_class_under(alsaDriver, "AlsaRemoveEvents_i", rb_cObject);

  alsa_seq_init();
  alsa_midi_queue_init();
  alsa_midi_client_init();
  alsa_midi_event_init();
  alsa_midi_port_init();
  port_subscription_init();
  alsa_remove_init();
  alsa_client_pool_init();
  alsa_system_info_init();
  alsa_midi_plusplus_init();
}
