
#pragma implementation

#include "alsa_midi_client.h"
#include "alsa_midi.h"
#include <ruby/dl.h>
#include <alsa/asoundlib.h>

#if defined(DUMP_API)
#define DUMP_STREAM stderr
#endif

VALUE alsaClientInfoClass;

/** Document-method: RRTS::Driver::AlsaClientInfo_i#copy_to
call-seq: copy_to([other = nil]) -> AlsaClientInfo_i

Make a duplicate. Used internally by AlsaClientInfo_i#initialize_copy.

Parameters:
[other] if a RRTS::Driver::AlsaClientInfo_i is passed here we copy +self+ into it,
        otherwise this method returns a new copy of itself.
*/
ALSA_MIDI_COPY_TO_TEMPLATE(client_info, ClientInfo)

/** call-seq: client = clientid

Set the client id of a client_info container. After this information can be retrieved.

Parameters:
[client]  client id
*/
static VALUE
wrap_snd_seq_client_info_set_client(VALUE v_client_info, VALUE v_clientid)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  snd_seq_client_info_set_client(client_info, NUM2INT(v_clientid));
  return Qnil;
}

/** call-seq: client() -> int

Get the clientid of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_client(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2NUM(snd_seq_client_info_get_client(client_info));
}

/** call-seq:  type() -> int

Get client type of a client_info container.
Can be +SND_SEQ_USER_CLIENT+ or +SND_SEQ_KERNEL_CLIENT+
*/
static VALUE
wrap_snd_seq_client_info_get_type(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2NUM(snd_seq_client_info_get_type(client_info));
}

/** call-seq: name() -> string

Get the name of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_name(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return rb_str_new2(snd_seq_client_info_get_name(client_info));
}

/** call-seq:  broadcast_filter?() -> bool

Returns: the broadcast filter usage of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_broadcast_filter(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2BOOL(snd_seq_client_info_get_broadcast_filter(client_info));
}

/** call-seq: error_bounce?() -> bool

Returns: the error-bounce usage of a client_info container. But what is it?
*/
static VALUE
wrap_snd_seq_client_info_get_error_bounce(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2BOOL(snd_seq_client_info_get_error_bounce(client_info));
}

/** call-seq: num_ports() -> int

Returns: the number of opened ports of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_num_ports(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2NUM(snd_seq_client_info_get_num_ports(client_info));
}

/** call-seq: event_lost() -> int

Returns: the number of lost events of a client_info container. Also available using
         the name +events_lost+.
*/
static VALUE
wrap_snd_seq_client_info_get_event_lost(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2NUM(snd_seq_client_info_get_event_lost(client_info));
}

void
alsa_midi_client_init()
{
  // possible values for 'type':
  WRAP_CONSTANT(SND_SEQ_USER_CLIENT);
  WRAP_CONSTANT(SND_SEQ_KERNEL_CLIENT);
  // must be in this file, or rdoc will not document it
  if (0)  // this is to make rdoc document it.
    {
       VALUE rrtsModule = rb_define_module("RRTS");
       alsaDriver = rb_define_module_under(rrtsModule, "Driver");
    }
/** Document-class: RRTS::Driver::AlsaClientInfo_i

This class stands for Alsa-clients ie, owners of Alsa connections, however, as its name suggests, it
is primarily used for retrieving information.

A RRTS::Driver::AlsaSequencer_i is also a client, and its clientid can be retrieved with
the method RRTS::Driver::AlsaSequencer_i#client_id

while the infoblock can be queried like this:

    i = RRTS::Driver::client_info_malloc
    i.client = sequencer.client_id
    if i.event_lost > 3  # etc.

Context: this class is pretty useless. Except maybe for RRTS::Driver::AlsaClientInfo_i#events_lost.
You probably want to use RRTS::MidiClient or use RRTS::Sequencer#client and RRTS::Sequencer#clients
to gain access to the clientinformation.
*/
  alsaClientInfoClass = rb_define_class_under(alsaDriver, "AlsaClientInfo_i", rb_cObject);
  rb_define_method(alsaClientInfoClass, "client=", RUBY_METHOD_FUNC(wrap_snd_seq_client_info_set_client), 1);
  rb_define_method(alsaClientInfoClass, "client", RUBY_METHOD_FUNC(wrap_snd_seq_client_info_get_client), 0);
  rb_define_method(alsaClientInfoClass, "name", RUBY_METHOD_FUNC(wrap_snd_seq_client_info_get_name), 0);
  rb_define_method(alsaClientInfoClass, "broadcast_filter?", RUBY_METHOD_FUNC(wrap_snd_seq_client_info_get_broadcast_filter), 0);
  rb_define_method(alsaClientInfoClass, "error_bounce?", RUBY_METHOD_FUNC(wrap_snd_seq_client_info_get_error_bounce), 0);
  rb_define_method(alsaClientInfoClass, "event_lost", RUBY_METHOD_FUNC(wrap_snd_seq_client_info_get_event_lost), 0);
  rb_define_method(alsaClientInfoClass, "events_lost", RUBY_METHOD_FUNC(wrap_snd_seq_client_info_get_event_lost), 0);
  rb_define_method(alsaClientInfoClass, "num_ports", RUBY_METHOD_FUNC(wrap_snd_seq_client_info_get_num_ports), 0);
  rb_define_method(alsaClientInfoClass, "type", RUBY_METHOD_FUNC(wrap_snd_seq_client_info_get_type), 0);
  rb_define_method(alsaClientInfoClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_client_info_copy_to), -1);
}
