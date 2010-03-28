
#pragma implementation

#include "alsa_midi_port.h"
#include "alsa_midi.h"
#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaPortInfoClass;

/* call-seq:
    client=(clientid)

Set the client or clientid of a port_info container, that is to be created
Parameters:
   [client] clientid or MidiClient
*/
static VALUE
wrap_snd_seq_port_info_set_client(VALUE v_port_info, VALUE v_clientid)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  RRTS_DEREF_DIRTY(v_clientid, @client);
  snd_seq_port_info_set_client(port_info, NUM2INT(v_clientid));
  return Qnil;
}

/* call-seq:
   port=(portid)
Set the port id of a port_info container.
Parameters:
port    portid, can be nil to unset the port

Setting it will set _port_specified_ to 1 (true), and also setting it to nil
will set _port_specified_ to 0 (false).

To be used for a port being created
*/
static VALUE
wrap_snd_seq_port_info_set_port(VALUE v_port_info, VALUE v_portnr)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  if (NIL_P(v_portnr))
    {
//       fprintf(stderr, "snd_seq_port_info_set_port_specified(%d)\n", 0);
      snd_seq_port_info_set_port_specified(port_info, 0);
    }
  else
    {
      snd_seq_port_info_set_port(port_info, NUM2INT(v_portnr));
//       fprintf(stderr, "snd_seq_port_info_set_port_specified(%d)\n", 1);
      snd_seq_port_info_set_port_specified(port_info, 1);
    }
  return Qnil;
}

/* port_specified=(bool)
Set the port-specified mode of a port_info container. This method is not
required since setting the port will automatically set it. See #port=

Parameters:
  [val] true if specifying the port id at creation. This also seems to
        be the default.
*/
static VALUE
wrap_snd_seq_port_info_set_port_specified(VALUE v_port_info, VALUE v_bool)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  const int b = BOOL2INT(v_bool);
//   fprintf(stderr, "snd_seq_port_info_set_port_specified(%d)\n", b);
  snd_seq_port_info_set_port_specified(port_info, b);
  return Qnil;
}

/* call-seq:
      client -> int
Returns the clientid
*/
static VALUE
wrap_snd_seq_port_info_get_client(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return INT2NUM(snd_seq_port_info_get_client(port_info));
}

/* call-seq:
       port -> int
Returns the portid
*/
static VALUE
wrap_snd_seq_port_info_get_port(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return INT2NUM(snd_seq_port_info_get_port(port_info));
}

/* call-seq:
    addr -> [client, port]
Returns the address as a tuple of two integers
*/
static VALUE
wrap_snd_seq_port_info_get_addr(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  const snd_seq_addr_t * const adr = snd_seq_port_info_get_addr(port_info);
  return rb_ary_new3(2, INT2NUM(adr->client), INT2NUM(adr->port));
}

/* call-seq:
    name -> string
Returns the name of the port
*/
static VALUE
wrap_snd_seq_port_info_get_name(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return rb_str_new2(snd_seq_port_info_get_name(port_info));
}

/* int capability
Returns the capabilities as a bitmap. Use the SND_SEQ_PORT_CAP constants for grogging this
*/
static VALUE
wrap_snd_seq_port_info_get_capability(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return INT2NUM(snd_seq_port_info_get_capability(port_info));
}

/* int midi_channels
Returns the number of channels supported by this port. Most ports will return 16
*/
static VALUE
wrap_snd_seq_port_info_get_midi_channels(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return INT2NUM(snd_seq_port_info_get_midi_channels(port_info));
}

/* call-seq:
    midi_voices -> int
Returns the number of voices present on the port. But many ports return 0 here
*/
static VALUE
wrap_snd_seq_port_info_get_midi_voices(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return INT2NUM(snd_seq_port_info_get_midi_voices(port_info));
}

/* call-seq:
   port_specified? -> bool
Returns true if a portnumber was explicitely set by the user when the
port was created
*/
static VALUE
wrap_snd_seq_port_info_get_port_specified(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return INT2BOOL(snd_seq_port_info_get_port_specified(port_info));
}

/* call-seq:
     read_use -> int
Returns the number of read-subscriptions on the port
*/
static VALUE
wrap_snd_seq_port_info_get_read_use(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return INT2NUM(snd_seq_port_info_get_read_use(port_info));
}

/* call-seq:
    write_use -> int
Returns the number of write-subscriptions on the port
*/
static VALUE
wrap_snd_seq_port_info_get_write_use(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return INT2NUM(snd_seq_port_info_get_write_use(port_info));
}

/* call-seq:
      synth_voices -> int
Returns the number of non-MIDI(?) voices
*/
static VALUE
wrap_snd_seq_port_info_get_synth_voices(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return INT2NUM(snd_seq_port_info_get_synth_voices(port_info));
}

/* call-seq:
   timestamp_queue -> int
Returns the queueid of the timestamp queue associated with the port.
*/
static VALUE
wrap_snd_seq_port_info_get_timestamp_queue(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return INT2NUM(snd_seq_port_info_get_timestamp_queue(port_info));
}

/* call-seq:
     timestamp_real? -> bool
Returns true if timestamps are given in realtime
*/
static VALUE
wrap_snd_seq_port_info_get_timestamp_real(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return INT2BOOL(snd_seq_port_info_get_timestamp_real(port_info));
}

/* call-seq:
   timestamping? -> bool
Returns true if the port will timestamp events automatically on arrival
*/
static VALUE
wrap_snd_seq_port_info_get_timestamping(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return INT2BOOL(snd_seq_port_info_get_timestamping(port_info));
}

/* call-seq:
     type -> int
Returns the type bitset. Use the SND_SEQ_PORT_TYPE... constants to
interpret the result
*/
static VALUE
wrap_snd_seq_port_info_get_type(VALUE v_port_info)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  return INT2NUM(snd_seq_port_info_get_type(port_info));
}

/* call-seq:
     timestamping=(bool)
Switch auto-timestamping on or off.  Note that the port needs a timestamp-queue
as well to actually activate it.
*/
static VALUE
wrap_snd_seq_port_info_set_timestamping(VALUE v_port_info, VALUE v_bool)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  snd_seq_port_info_set_timestamping(port_info, BOOL2INT(v_bool));
  return Qnil;
}

/* call-seq:
     midi_voices=(count)
Set the number of MIDI voices this port supports.
*/
static VALUE
wrap_snd_seq_port_info_set_midi_voices(VALUE v_port_info, VALUE v_count)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  snd_seq_port_info_set_midi_voices(port_info, NUM2INT(v_count));
  return Qnil;
}

/* call-seq:
     synth_voices=(count)
Sets the number of synth voices the port supports
*/
static VALUE
wrap_snd_seq_port_info_set_synth_voices(VALUE v_port_info, VALUE v_count)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  snd_seq_port_info_set_synth_voices(port_info, NUM2INT(v_count));
  return Qnil;
}

/* call-seq:
     midi_channels=(count)
Sets the number of MIDI channels the port supports
*/
static VALUE
wrap_snd_seq_port_info_set_midi_channels(VALUE v_port_info, VALUE v_count)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  snd_seq_port_info_set_midi_channels(port_info, NUM2INT(v_count));
  return Qnil;
}

/* call-seq:
     type=(bits)
Set a combination of SND_SEQ_PORT_TYPE flags to indicate what kind of port this will be
*/
static VALUE
wrap_snd_seq_port_info_set_type(VALUE v_port_info, VALUE v_bits)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  snd_seq_port_info_set_type(port_info, NUM2UINT(v_bits));
  return Qnil;
}

/* call-seq:
    capability=(bits)
Set a combination of SND_SEQ_PORT_CAP flags to indicate what this port can do
*/
static VALUE
wrap_snd_seq_port_info_set_capability(VALUE v_port_info, VALUE v_bits)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  snd_seq_port_info_set_capability(port_info, NUM2UINT(v_bits));
  return Qnil;
}

/* call-seq:
    name=(string)
Sets the port name. Note: must be called prior to creating a port
*/
static VALUE
wrap_snd_seq_port_info_set_name(VALUE v_port_info, VALUE v_name)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  snd_seq_port_info_set_name(port_info, StringValuePtr(v_name));
  return Qnil;
}

/* call-seq:
    timestamp_real=(bool)
Set the timestamping mode to realtime. You need to activate timestamping, and you
need a timestamp-queue to truly activate this.
*/
static VALUE
wrap_snd_seq_port_info_set_timestamp_real(VALUE v_port_info, VALUE v_bool)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  snd_seq_port_info_set_timestamp_real(port_info, BOOL2INT(v_bool));
  return Qnil;
}

/* call-seq:
    timestamp_queue=(queue)
Set the timestamp-queue
*/
static VALUE
wrap_snd_seq_port_info_set_timestamp_queue(VALUE v_port_info, VALUE v_qid)
{
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  RRTS_DEREF_DIRTY(v_qid, @id);
  snd_seq_port_info_set_timestamp_queue(port_info, NUM2INT(v_qid));
  return Qnil;
}

/* call-seq:
    copy_to -> other
    copy_to(other) -> self
Make a copy of this record. Without an argument it returns a copy.
*/
static VALUE
wrap_snd_seq_port_info_copy_to(int argc, VALUE *argv, VALUE v_port_info)
{
  VALUE v_dst;
  rb_scan_args(argc, argv, "01", &v_dst);
  snd_seq_port_info_t *port_info, *dst;
  VALUE retval = v_port_info;
  if (NIL_P(v_dst))
    {
      const int r = snd_seq_port_info_malloc(&dst);
      if (r < 0) RAISE_MIDI_ERROR("allocating port_info", r);
      v_dst = Data_Wrap_Struct(alsaPortInfoClass, 0/*mark*/, snd_seq_port_info_free/*free*/, dst);
      retval = v_dst;
    }
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  Data_Get_Struct(v_dst, snd_seq_port_info_t, dst);
  snd_seq_port_info_copy(dst, port_info);
  return retval;
}

/* AlsaMidiPort_i

This class represents a snd_seq_port_info_t structure. It can be used to create a port with,
or it can be used to queury a port's attributes
*/
void
alsa_midi_port_init()
{
  alsaPortInfoClass = rb_define_class_under(alsaDriver, "AlsaPortInfo_i", rb_cObject);
  rb_define_method(alsaPortInfoClass, "port", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_port), 0);
  rb_define_method(alsaPortInfoClass, "client", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_client), 0);
  rb_define_method(alsaPortInfoClass, "addr", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_addr), 0);
  rb_define_method(alsaPortInfoClass, "capability", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_capability), 0);
  // the possible values are listed above
  rb_define_method(alsaPortInfoClass, "midi_channels", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_midi_channels), 0);
  rb_define_method(alsaPortInfoClass, "midi_voices", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_midi_voices), 0);
  rb_define_method(alsaPortInfoClass, "name", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_name), 0);
  // was the port fixed by the user or generated?
  rb_define_method(alsaPortInfoClass, "port_specified?", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_port_specified), 0);
  rb_define_method(alsaPortInfoClass, "read_use", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_read_use), 0);
  rb_define_method(alsaPortInfoClass, "synth_voices", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_synth_voices), 0);
  rb_define_method(alsaPortInfoClass, "timestamp_queue", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_timestamp_queue), 0);
  rb_define_method(alsaPortInfoClass, "timestamp_real?", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_timestamp_real), 0);
  rb_define_method(alsaPortInfoClass, "timestamping?", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_timestamping), 0);
  rb_define_method(alsaPortInfoClass, "client=", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_set_client), 1);
  rb_define_method(alsaPortInfoClass, "port=", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_set_port), 1);
  rb_define_method(alsaPortInfoClass, "port_specified=", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_set_port_specified), 1);
  rb_define_method(alsaPortInfoClass, "timestamp_queue=", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_set_timestamp_queue), 1);
  rb_define_method(alsaPortInfoClass, "timestamp_real=", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_set_timestamp_real), 1);
  rb_define_method(alsaPortInfoClass, "timestamping=", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_set_timestamping), 1);
  rb_define_method(alsaPortInfoClass, "synth_voices=", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_set_synth_voices), 1);
  rb_define_method(alsaPortInfoClass, "midi_voices=", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_set_midi_voices), 1);
  rb_define_method(alsaPortInfoClass, "midi_channels=", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_set_midi_channels), 1);
  rb_define_method(alsaPortInfoClass, "type=", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_set_type), 1);
  rb_define_method(alsaPortInfoClass, "capability=", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_set_capability), 1);
  rb_define_method(alsaPortInfoClass, "name=", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_set_name), 1);
  rb_define_method(alsaPortInfoClass, "type", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_type), 0);
  // the types are listed above
  rb_define_method(alsaPortInfoClass, "write_use", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_get_write_use), 0);
  rb_define_method(alsaPortInfoClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_port_info_copy_to), -1);

  // arg 2 for create_simple_port
  WRAP_CONSTANT(SND_SEQ_PORT_CAP_READ); // Readable from this port
  WRAP_CONSTANT(SND_SEQ_PORT_CAP_WRITE); // Writable to this port.
  WRAP_CONSTANT(SND_SEQ_PORT_CAP_SYNC_READ); // For synchronization (not implemented)
  WRAP_CONSTANT(SND_SEQ_PORT_CAP_SYNC_WRITE); // For synchronization (not implemented)
  WRAP_CONSTANT(SND_SEQ_PORT_CAP_DUPLEX); // Read/write duplex access is supported
  WRAP_CONSTANT(SND_SEQ_PORT_CAP_SUBS_READ); // Read subscription is allowed
  WRAP_CONSTANT(SND_SEQ_PORT_CAP_SUBS_WRITE); // Write subscription is allowed
  WRAP_CONSTANT(SND_SEQ_PORT_CAP_NO_EXPORT); // Subscription management from 3rd client is disallowed

  // arg 3 for create_simple_port
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_SPECIFIC); // Hardware specific port
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_MIDI_GENERIC); // Generic MIDI device
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_MIDI_GM); // General MIDI compatible device
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_DIRECT_SAMPLE); // supports downloads of instruments
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_SAMPLE); // supports downloads of instruments
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_MIDI_GM2); // General MIDI 2 compatible device
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_MIDI_GS); // GS compatible device
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_MIDI_XG); // XG compatible device
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_MIDI_MT32); //  MT-32 compatible device
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_HARDWARE); // Implemented in hardware
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_SOFTWARE); // Implemented in software
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_SYNTH); // supports SAMPLE events (alsa(?) not MIDI)
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_SYNTHESIZER); // Generates sound
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_PORT); // Connects to other device(s)
  WRAP_CONSTANT(SND_SEQ_PORT_TYPE_APPLICATION); // Application (sequencer/editor)


}
