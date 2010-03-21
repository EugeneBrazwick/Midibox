
#pragma implementation

#include "alsa_midi_client.h"
#include "alsa_midi.h"
#include <ruby/dl.h>
#include <alsa/asoundlib.h>

#if defined(DUMP_API)
#define DUMP_STREAM stderr
#endif

VALUE alsaClientInfoClass;

/* call-seq:
     client_info.copy_to other -> client_info
     client_info.copy_to       -> client_info

Make a duplicate. Used internally by AlsaClientInfo_i#initialize_copy.
The second form creates an actual clone
*/
ALSA_MIDI_COPY_TO_TEMPLATE(client_info, ClientInfo)

/* call-seq:
   ClientInfo.client= clientid

Set the client id of a client_info container.

Parameters:
client  client id
*/
static VALUE
wrap_snd_seq_client_info_set_client(VALUE v_client_info, VALUE v_clientid)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  snd_seq_client_info_set_client(client_info, NUM2INT(v_clientid));
  return Qnil;
}

/* call-seq:
  ClientInfo#client -> int

Get the clientid of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_client(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2NUM(snd_seq_client_info_get_client(client_info));
}

/* call-seq:
   ClientInfo#type -> int
Get client type of a client_info container. Can be SND_SEQ_USER_CLIENT
 or SND_SEQ_KERNEL_CLIENT
*/
static VALUE
wrap_snd_seq_client_info_get_type(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2NUM(snd_seq_client_info_get_type(client_info));
}

/* call-seq:
   ClientInfo#name -> string
Get the name of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_name(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return rb_str_new2(snd_seq_client_info_get_name(client_info));
}

/* call-seq:
ClientInfo#broadcast_filter? -> bool
Get the broadcast filter usage of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_broadcast_filter(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2BOOL(snd_seq_client_info_get_broadcast_filter(client_info));
}

/* call-seq:
   ClientInfo#error_bounce? -> bool
Get the error-bounce usage of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_error_bounce(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2BOOL(snd_seq_client_info_get_error_bounce(client_info));
}

/* call-seq:
   ClientInfo#num_ports -> int
Get the number of opened ports of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_num_ports(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2NUM(snd_seq_client_info_get_num_ports(client_info));
}

/* call-seq:
 ClientInfo#event_lost -> int
Get the number of lost events of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_event_lost(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2NUM(snd_seq_client_info_get_event_lost(client_info));
}

/* AlsaMidiClient_i is used to external clients or the sequencer client itself.
*/
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
