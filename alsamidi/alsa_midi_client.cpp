
#pragma implementation

#include "alsa_midi_client.h"
#include "alsa_midi.h"
#include <ruby/dl.h>
#include <alsa/asoundlib.h>

#if defined(DUMP_API)
#define DUMP_STREAM stderr
#endif

VALUE alsaClientInfoClass;

/* self ClientInfo#copy_to dst
 dst ClientInfo#copy_to
*/
static VALUE
wrap_snd_seq_client_info_copy_to(int argc, VALUE *argv, VALUE v_client_info)
{
  VALUE v_dst;
  rb_scan_args(argc, argv, "01", &v_dst);
  VALUE retval = v_client_info;
  snd_seq_client_info_t *client_info, *dst;
  if (NIL_P(v_dst))
    {
      const int r = snd_seq_client_info_malloc(&dst);
      if (r < 0) RAISE_MIDI_ERROR("allocation client info", r);
      v_dst = Data_Wrap_Struct(alsaClientInfoClass, 0/*mark*/, snd_seq_client_info_free/*free*/, dst);
      retval = v_dst;
    }
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  Data_Get_Struct(v_dst, snd_seq_client_info_t, dst);
  snd_seq_client_info_copy(dst, client_info);
  return retval;
}

/* ClientInfo.client= clientid

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

/*
int ClientInfo#client

Get client id of a client_info container.


Returns:
  client id
*/
static VALUE
wrap_snd_seq_client_info_get_client(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2NUM(snd_seq_client_info_get_client(client_info));
}

/*
int ClientInfo#type
Get client type of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_type(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2NUM(snd_seq_client_info_get_type(client_info));
}

/*
 string ClientInfo#name
Get the name of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_name(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return rb_str_new2(snd_seq_client_info_get_name(client_info));
}

/*
bool ClientInfo#broadcast_filter?
Get the broadcast filter usage of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_broadcast_filter(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2BOOL(snd_seq_client_info_get_broadcast_filter(client_info));
}

/*
bool ClientInfo#error_bounce?
Get the error-bounce usage of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_error_bounce(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2BOOL(snd_seq_client_info_get_error_bounce(client_info));
}

/*
int    ClientInfo#num_ports
Get the number of opened ports of a client_info container.
*/
static VALUE
wrap_snd_seq_client_info_get_num_ports(VALUE v_client_info)
{
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  return INT2NUM(snd_seq_client_info_get_num_ports(client_info));
}

/*
int ClientInfo#event_lost
Get the number of lost events of a client_info container.
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
  alsaClientInfoClass = rb_define_class_under(alsaDriver, "AlsaClientInfo_i", rb_cObject);
  // possible values for 'type':
  WRAP_CONSTANT(SND_SEQ_USER_CLIENT);
  WRAP_CONSTANT(SND_SEQ_KERNEL_CLIENT);
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
