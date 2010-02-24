
#pragma implementation

#include "alsa_port_subscription.h"
#include "alsa_midi.h"
#include "alsa_midi_client.h"
#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaPortSubscriptionClass;

/* client, port PortSubscription#dest

Get destination address of a port_subscribe container.
*/
static VALUE
wrap_snd_seq_port_subscribe_get_dest(VALUE v_port_subs)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  const snd_seq_addr_t * const adr = snd_seq_port_subscribe_get_dest(port_subs);
  return rb_ary_new3(2, INT2NUM(adr->client), INT2NUM(adr->port));
}

// clientid PortSubscription#dest_client
static VALUE
wrap_snd_seq_port_subscribe_get_dest_client(VALUE v_port_subs)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  const snd_seq_addr_t * const adr = snd_seq_port_subscribe_get_dest(port_subs);
  return INT2NUM(adr->client);
}

// portid PortSubscription#dest_port
static VALUE
wrap_snd_seq_port_subscribe_get_dest_port(VALUE v_port_subs)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  const snd_seq_addr_t * const adr = snd_seq_port_subscribe_get_dest(port_subs);
  return INT2NUM(adr->port);
}

/* bool PortSubscription#exclusive?
Get the exclusive mode of a port_subscribe container.
Returns:
   true if exclusive mode
*/
static VALUE
wrap_snd_seq_port_subscribe_get_exclusive(VALUE v_port_subs)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  return INT2BOOL(snd_seq_port_subscribe_get_exclusive(port_subs));
}

/* int PortSubscription#queue
Get the queue id of a port_subscribe container.
Reurns:
  queue id
*/
static VALUE
wrap_snd_seq_port_subscribe_get_queue(VALUE v_port_subs)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  return INT2NUM(snd_seq_port_subscribe_get_queue(port_subs));
}

/* client, port PortSubscription#sender
Get sender address of a port_subscribe container.
*/
static VALUE
wrap_snd_seq_port_subscribe_get_sender(VALUE v_port_subs)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  const snd_seq_addr_t * const adr = snd_seq_port_subscribe_get_sender(port_subs);
  return rb_ary_new3(2, INT2NUM(adr->client), INT2NUM(adr->port));
}

// client PortSubscription#sender_client
static VALUE
wrap_snd_seq_port_subscribe_get_sender_client(VALUE v_port_subs)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  const snd_seq_addr_t * const adr = snd_seq_port_subscribe_get_sender(port_subs);
  return INT2NUM(adr->client);
}

// port PortSubscription#sender_port
static VALUE
wrap_snd_seq_port_subscribe_get_sender_port(VALUE v_port_subs)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  const snd_seq_addr_t * const adr = snd_seq_port_subscribe_get_sender(port_subs);
  return INT2NUM(adr->port);
}

/* bool PortSubscription#time_real?
Get the real-time update mode of a port_subscribe container.
Returns:
 true if real-time update mode
*/
static VALUE
wrap_snd_seq_port_subscribe_get_time_real(VALUE v_port_subs)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  return INT2BOOL(snd_seq_port_subscribe_get_time_real(port_subs));
}

/* bool PortSubscription#time_update?
Get the time-update mode of a port_subscribe container.
Returns:
  true if update timestamp
*/
static VALUE
wrap_snd_seq_port_subscribe_get_time_update(VALUE v_port_subs)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  return INT2BOOL(snd_seq_port_subscribe_get_time_update(port_subs));
}

#define FETCH_ADDRESSES() \
VALUE v_clientid, v_portid; \
rb_scan_args(argc, argv, "11", &v_clientid, &v_portid); \
solve_address(v_clientid, v_portid)
/*
PortSubscription.set_dest client, port
PortSubscription.set_dest addr
PortSubscription.dest= addr

Set destination address of a port_subscribe container.

Parameters:
  client - clientid
  port - portid
  addr - destination address
*/
static VALUE
wrap_snd_seq_port_subscribe_set_dest(int argc, VALUE *argv, VALUE v_port_subs)
{
  FETCH_ADDRESSES();
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  snd_seq_addr_t addr = { NUM2INT(v_clientid), NUM2INT(v_portid) };
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_port_subscribe_set_destination(%p, {%d, %d})\n", port_subs, NUM2INT(v_clientid), NUM2INT(v_portid));
#endif
  snd_seq_port_subscribe_set_dest(port_subs, &addr);
  return Qnil;
}

/* PortSubscription#exclusive = bool
Set the exclusive mode of a port_subscribe container.
Parameters:
val     true to enable
*/
static VALUE
wrap_snd_seq_port_subscribe_set_exclusive(VALUE v_port_subs, VALUE v_val)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  snd_seq_port_subscribe_set_exclusive(port_subs, BOOL2INT(v_val));
  return Qnil;
}

/* PortSubscription#queue= qid
Set the queue id of a port_subscribe container.
Parameters:
qid       queue id
*/
static VALUE
wrap_snd_seq_port_subscribe_set_queue(VALUE v_port_subs, VALUE v_queue_id)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  //fprintf(stderr, __FILE__ ":%d:snd_seq_port_subscribe_set_queue(%d)\n", __LINE__, NUM2INT(v_queue_id));
  #if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_port_subscribe_set_queue(%p, %d)\n", port_subs, NUM2INT(v_queue_id));
  #endif
  snd_seq_port_subscribe_set_queue(port_subs, NUM2INT(v_queue_id));
  return Qnil;
}

/* PortSubscription#set_sender client, port
   PortSubscription#set_sender addr
   PortSubscription#sender= addr
Set sender address of a port_subscribe container.
Parameters:
  addr    sender address
*/
static VALUE
wrap_snd_seq_port_subscribe_set_sender(int argc, VALUE *argv, VALUE v_port_subs)
{
  FETCH_ADDRESSES();
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  snd_seq_addr_t addr = { NUM2INT(v_clientid), NUM2INT(v_portid) };
  #if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_port_subscribe_set_sender(%p, {%d, %d})\n", port_subs, NUM2INT(v_clientid), NUM2INT(v_portid));
  #endif
  snd_seq_port_subscribe_set_sender(port_subs, &addr);
  return Qnil;
}

/* PortSubscription#real_time= bool
Set the real-time mode of a port_subscribe container.
Parameters:
  val     true to enable
*/
static VALUE
wrap_snd_seq_port_subscribe_set_time_real(VALUE v_port_subs, VALUE v_val)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  //   fprintf(stderr, __FILE__ ":%d:snd_seq_port_subscribe_set_time_real(%d)\n", __LINE__, BOOL2INT(v_val));
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_port_subscribe_set_time_real(%p, %s)\n", port_subs, BOOL2INT(v_val) ? "true" : "false");
#endif
  snd_seq_port_subscribe_set_time_real(port_subs, BOOL2INT(v_val));
  return Qnil;
}

/*  PortSubscription#time_update= bool
Set the time-update mode of a port_subscribe container.
Parameters:
val     true to enable
*/
static VALUE
wrap_snd_seq_port_subscribe_set_time_update(VALUE v_port_subs, VALUE v_val)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  //   fprintf(stderr, __FILE__ ":%d:snd_seq_port_subscribe_set_time_update(%d)\n", __LINE__, BOOL2INT(v_val));
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_port_subscribe_set_time_update(%p, %s)\n", port_subs, BOOL2INT(v_val) ? "true" : "false");
#endif
  snd_seq_port_subscribe_set_time_update(port_subs, BOOL2INT(v_val));
  return Qnil;
}

void
port_subscription_init()
{
  alsaPortSubscriptionClass = rb_define_class_under(alsaDriver, "AlsaPortSubscription_i", rb_cObject);

  rb_define_method(alsaPortSubscriptionClass, "dest", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_get_dest), 0);
  rb_define_method(alsaPortSubscriptionClass, "dest_client", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_get_dest_client), 0);
  rb_define_method(alsaPortSubscriptionClass, "dest_port", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_get_dest_port), 0);
  rb_define_method(alsaPortSubscriptionClass, "exclusive?", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_get_exclusive), 0);
  rb_define_method(alsaPortSubscriptionClass, "queue", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_get_queue), 0);
  rb_define_method(alsaPortSubscriptionClass, "sender", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_get_sender), 0);
  rb_define_method(alsaPortSubscriptionClass, "sender_client", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_get_sender_client), 0);
  rb_define_method(alsaPortSubscriptionClass, "sender_port", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_get_sender_port), 0);
  rb_define_method(alsaPortSubscriptionClass, "time_real?", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_get_time_real), 0);
  rb_define_method(alsaPortSubscriptionClass, "time_update?", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_get_time_update), 0);
  rb_define_method(alsaPortSubscriptionClass, "set_dest", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_set_dest), -1);
  rb_define_method(alsaPortSubscriptionClass, "dest=", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_set_dest), -1);
  rb_define_method(alsaPortSubscriptionClass, "exclusive=", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_set_exclusive), 1);
  rb_define_method(alsaPortSubscriptionClass, "queue=", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_set_queue), 1);
  rb_define_method(alsaPortSubscriptionClass, "set_sender", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_set_sender), -1);
  rb_define_method(alsaPortSubscriptionClass, "sender=", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_set_sender), -1);
  rb_define_method(alsaPortSubscriptionClass, "time_real=", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_set_time_real), 1);
  rb_define_method(alsaPortSubscriptionClass, "time_update=", RUBY_METHOD_FUNC(wrap_snd_seq_port_subscribe_set_time_update), 1);

}
