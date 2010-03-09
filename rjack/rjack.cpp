#include <ruby.h>
#include <jack/jack.h>
#include <jack/midiport.h>

static VALUE rJackClientClass, rJackPortClass;

static VALUE
wrap_jack_client_close(VALUE v_mod, VALUE v_client) /* :no-doc: */
{
  jack_client_t * client;
  Data_Get_Struct(v_client, jack_client_t, client);
  jack_client_close(client);
  return Qnil;
}

static VALUE
wrap_jack_client_open(VALUE v_mod, VALUE v_name, VALUE v_options, VALUE v_servername) /* :no-doc: */
{
  const char *const servername = StringValueCStr(v_servername);
  const bool hasServername = servername[0];
  const int options = (NUM2INT(v_options) | (hasServername ? JackServerName : 0)) & JackOpenOptions;
  jack_status_t result = jack_status_t(0);
  jack_client_t * const client = jack_client_open(StringValueCStr(v_name), jack_options_t(options), &result, servername);
  VALUE v_client = client ? Data_Wrap_Struct(rJackClientClass, 0, 0, client) : Qnil;
  VALUE ret = rb_ary_new2(2);
  rb_ary_push(ret, v_client);
  rb_ary_push(ret, INT2NUM(int(result)));
  return ret;
}

static VALUE
wrap_jack_get_ports(VALUE v_mod, VALUE v_client, VALUE v_nampat, VALUE v_tppat, VALUE v_flags) /* :no-doc: */
{
//fprintf(stderr, "wrap_jack_get_ports, arg1.inspect="); // SEGV !! rb_apply(v_mod, rb_intern("inspect"), Qnil);
  jack_client_t *client;
  Data_Get_Struct(v_client, jack_client_t, client);
//fprintf(stderr, "getting args\n");
  const char ** const res = jack_get_ports(client, StringValueCStr(v_nampat), StringValueCStr(v_tppat), NUM2INT(v_flags));
  if (!res) return Qnil;
  VALUE ret = rb_ary_new();
  for (const char ** s = res; *s; s++)
    rb_ary_push(ret, rb_str_new2(*s));
  return ret;
}

static VALUE
wrap_jack_port_register(VALUE v_mod, VALUE v_client, VALUE v_portname, VALUE v_type, VALUE v_flags, VALUE v_bufsz) /* :no-doc: */
{
  jack_client_t *client;
  Data_Get_Struct(v_client, jack_client_t, client);
  const char * const portname = StringValueCStr(v_portname);
  const char * const type = StringValueCStr(v_type);
  const int flags = NUM2INT(v_flags);
  const int bufsz = NUM2INT(v_bufsz);
  jack_port_t * const port = jack_port_register(client, portname, type, flags, bufsz);
  return port ? Data_Wrap_Struct(rJackPortClass, 0, 0, port) : Qnil;
}

static VALUE
wrap_jack_port_unregister(VALUE v_mod, VALUE v_client, VALUE v_port) /* :no-doc: */
{
  jack_client_t *client;
  Data_Get_Struct(v_client, jack_client_t, client);
  jack_port_t *port;
  Data_Get_Struct(v_port, jack_port_t, port);
  jack_port_unregister(client, port);
  return Qnil;
}

enum EMode { ModeRecording, ModeDumping };

struct Context
{
  jack_client_t *const client;
  jack_port_t *const softport; // port on our side. Not hardware we are reading from
  const EMode mode;
  const size_t rawMidiBufferSz;
  char *const rawMidiBuffer;
  char *rawMidiBufferPtr; // current pos.
  size_t ptr; // cached, same as rawMidiBufferPtr - rawMidiBuffer. Invar: ptr <= rawMidiBufferSz
  Context(jack_client_t *aClient, jack_port_t *aPort, EMode aMode, size_t sz):
    client(aClient),
    softport(aPort),
    mode(aMode),
    rawMidiBufferSz(sz),
    rawMidiBuffer((char *)malloc(sz)),
    rawMidiBufferPtr(rawMidiBuffer),
    ptr(0)
    {
    }
  ~Context() { ::free((void *)rawMidiBuffer); }
  size_t free() const { return rawMidiBufferSz - ptr; }
};

/* the second arg is basicly the data stored with registering the callback.
   For the sequencer we need only two different modes.
   Recording a midi piece into memory, and second the reverse.

   Returning non-zero will detach our client!

   It is NOT legal to use malloc, printf, sleep, thread functions (join/wait/mutex_lock) and likewise functions!

   I use errorcode to signal the caller
*/
static int
process_callback(jack_nframes_t nframes, Context *context)
{
  /* we could say that not receiving mididata for 10 seconds or so closes the recording
  if (get_delta_time() > MAX_TIME_BETWEEN_CALLBACKS) {
    ... // "Had to wait too long for JACK callback; scheduling problem?"
  }
  */

  /* Check for impossible condition that actually happened to me, caused by some problem between jackd and OSS4. */
  if (nframes <= 0) return 1;
  // int             events;
  static int      time_of_first_event = -1;

  const int last_frame_time = jack_last_frame_time(context->client);
  void * const port_buffer = jack_port_get_buffer(context->softport, nframes);
  if (!port_buffer) return 2;
  const jack_nframes_t events = jack_midi_get_event_count(port_buffer);
  for (size_t i = 0; i < events; i++)
    {
      jack_midi_event_t event; // where event.time is relative to the last_frame_time
      const int read = jack_midi_event_get(&event, port_buffer, i);
      if (read) continue; // can only be ENODATA
      // Ignore realtime messages. FIXME, should be switch ??
      if (event.buffer[0] >= 0xF8)
        continue;
      // First event received?
      if (time_of_first_event == -1)
        time_of_first_event = last_frame_time + event.time;
      if (event.size + sizeof(event.time) > context->free()) return 3; // midi buffer full!!
      memcpy(context->rawMidiBufferPtr, &event.time, sizeof(event.time));
      context->rawMidiBufferPtr += sizeof(event.time);
      memcpy(context->rawMidiBufferPtr, event.buffer, event.size);
      context->ptr += event.size + sizeof(event.time);
      context->rawMidiBufferPtr += event.size;
    }
}

extern "C" void
Init_rjack()
{
  VALUE rJackModule = rb_define_module("RJack"); /* :no-doc: */
#define WRAP_CONSTANT(s) rb_define_const(rJackModule, #s, INT2NUM(s))
#define WRAP_STRING_CONSTANT(s) rb_define_const(rJackModule, #s, rb_str_new2(s))
  WRAP_CONSTANT(JackNoStartServer);
  WRAP_CONSTANT(JackUseExactName);
  WRAP_CONSTANT(JackFailure);
  WRAP_CONSTANT(JackInitFailure);
  WRAP_CONSTANT(JackInvalidOption);
  WRAP_CONSTANT(JackNameNotUnique);
  WRAP_CONSTANT(JackServerError);
  WRAP_CONSTANT(JackServerFailed);
  WRAP_CONSTANT(JackServerStarted);
  WRAP_CONSTANT(JackShmFailure);
  WRAP_CONSTANT(JackNoSuchClient);
  WRAP_CONSTANT(JackLoadFailure);
  WRAP_CONSTANT(JackVersionError);
  WRAP_CONSTANT(JackPortIsInput);
  WRAP_CONSTANT(JackPortIsOutput);
  WRAP_CONSTANT(JackPortIsPhysical);
  WRAP_CONSTANT(JackPortCanMonitor);
  WRAP_CONSTANT(JackPortIsTerminal);  // meaning: an 'endpoint'. a final destination, but also a source (when output)
  WRAP_STRING_CONSTANT(JACK_DEFAULT_AUDIO_TYPE);
  WRAP_STRING_CONSTANT(JACK_DEFAULT_MIDI_TYPE);
  rJackClientClass = rb_define_class_under(rJackModule, "RJackClient", rb_cObject); /* :no-doc: */
  rJackPortClass = rb_define_class_under(rJackModule, "RJackPort", rb_cObject); /* :no-doc: */
  rb_define_module_function(rJackModule, "jack_client_open", RUBY_METHOD_FUNC(wrap_jack_client_open), 3);
  rb_define_module_function(rJackModule, "jack_client_close", RUBY_METHOD_FUNC(wrap_jack_client_close), 1);
  rb_define_module_function(rJackModule, "jack_get_ports", RUBY_METHOD_FUNC(wrap_jack_get_ports), 4);
  rb_define_module_function(rJackModule, "jack_port_register", RUBY_METHOD_FUNC(wrap_jack_port_register), 5);
  rb_define_module_function(rJackModule, "jack_port_unregister", RUBY_METHOD_FUNC(wrap_jack_port_unregister), 2);
}
