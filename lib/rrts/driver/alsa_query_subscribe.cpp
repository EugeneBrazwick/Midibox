
#pragma implementation
#include "alsa_query_subscribe.h"
#include "alsa_midi.h"
#include <alsa/asoundlib.h>
#include <ruby/ruby.h>
#include <ruby/dl.h>

VALUE alsaQuerySubscribeClass;

/** Document-method: RRTS::Driver::AlsaQuerySubscribe_i#copy_to
call-seq:  copy_to([other=nil]) -> clone

Parameters:
[other] if given copy +self+ to it, otherwise create a copy and return it. This copy need
        not be freed.
*/
ALSA_MIDI_COPY_TO_TEMPLATE(query_subscribe, QuerySubscribe)

/** call-seq: addr -> [clientid, portid]

Get the address of subscriber. This is the 'external' end of a connection, from
the initiating clients point of view.

If I say:

  ruby bin/rconnect.rb 20:1 14:0

to connect UM-out (sender 20:1) to MIDI-through-in (dest 14:0) then the connection is listed in the input list:

  client 14: 'Midi Through' [type=kernel]
    0 'Midi Through Port-0'
        Connected From: 20:1
  client 20: 'UM-2' [type=kernel]
    1 'UM-2 MIDI 2     '
        Connecting To: 14:0

Returns:
    subscriber's address pointer, that is the sender for 'connect-to' and the destination for 'connect-from'
    querytypes.

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers() and RRTS::Driver::AlsaQuerySubscribe_i#addr
*/
static VALUE
wrap_snd_seq_query_subscribe_get_addr(VALUE v_info)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  const snd_seq_addr_t * const addr = snd_seq_query_subscribe_get_addr(info);
  return rb_ary_new3(2, INT2NUM(addr->client), INT2NUM(addr->port));
}

/** call-seq: client -> int

Get the client id of a query_subscribe container.

Returns:
    client id

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers() and RRTS::Driver::AlsaQuerySubscribe_i#client=
*/
static VALUE
wrap_snd_seq_query_subscribe_get_client(VALUE v_info)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  return INT2NUM(snd_seq_query_subscribe_get_client(info));
}

/** call-seq: exclusive? -> bool

Get the exclusive mode of a query_subscribe container.

Returns:
    true if exclusive mode

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers()
*/
static VALUE
wrap_snd_seq_query_subscribe_get_exclusive(VALUE v_info)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  return INT2BOOL(snd_seq_query_subscribe_get_exclusive(info));
}

/** call-seq: index -> int

Returns:
    subscriber's index

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers() and RRTS::Driver::AlsaQuerySubscribe_i#index=
*/
static VALUE
wrap_snd_seq_query_subscribe_get_index(VALUE v_info)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  return INT2NUM(snd_seq_query_subscribe_get_index(info));
}

/** call-seq: num_subs -> int

Returns:
    the number of subscriptions

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers()
*/
static VALUE
wrap_snd_seq_query_subscribe_get_num_subs(VALUE v_info)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  return INT2NUM(snd_seq_query_subscribe_get_num_subs(info));
}

/** call-seq: port -> int

Returns:
    the port id

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers()  and RRTS::Driver::AlsaQuerySubscribe_i#port=
*/
static VALUE
wrap_snd_seq_query_subscribe_get_port(VALUE v_info)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  return INT2NUM(snd_seq_query_subscribe_get_port(info));
}

/** call-seq: queue -> int

Returns:
    the queue id

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers()
*/
static VALUE
wrap_snd_seq_query_subscribe_get_queue(VALUE v_info)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  return INT2NUM(snd_seq_query_subscribe_get_queue(info));
}

/** call-seq: root -> [clientid, portid]

Get the root address

Returns:
    subscriber's root address pointer, for the READ (or 'connect-to') query type, +root+ is the sender,
    otherwise it is the destination. So we have:

        ROOT connect to ADDR,                           SENDER -> DEST

    or

        ROOT connect from ADDR                          DEST <- SENDER


See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers(), RRTS::Driver::AlsaQuerySubscribe_i#root= and
    RRTS::Driver::AlsaQuerySubscribe_i#addr
*/
static VALUE
wrap_snd_seq_query_subscribe_get_root(VALUE v_info)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  const snd_seq_addr_t * const addr = snd_seq_query_subscribe_get_root(info);
  return rb_ary_new3(2, INT2NUM(addr->client), INT2NUM(addr->port));
}

/** call-seq: time_real? -> bool

Get the realtime update mode of a query_subscribe container.

Returns:
    true if realtime update mode

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers()
*/
static VALUE
wrap_snd_seq_query_subscribe_get_time_real(VALUE v_info)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  return INT2BOOL(snd_seq_query_subscribe_get_time_real(info));
}

/** call-seq: time_update? -> bool

Get the time-update mode

Returns:
    true if timestamps are updated

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers()
*/
static VALUE
wrap_snd_seq_query_subscribe_get_time_update(VALUE v_info)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  return INT2BOOL(snd_seq_query_subscribe_get_time_update(info));
}

/** call-seq: type -> int
snd_seq_query_subs_type_t snd_seq_query_subscribe_get_type      (       const snd_seq_query_subscribe_t *       info     )

Get the query type

Parameters:
        info    query_subscribe container

Returns:
    query type, either SND_SEQ_QUERY_SUBS_READ or SND_SEQ_QUERY_SUBS_WRITE

See also:
     RRTS::Driver::AlsaSequencer_i#query_port_subscribers() and  RRTS::Driver::AlsaQuerySubscribe_i#type=
*/
static VALUE
wrap_snd_seq_query_subscribe_get_type(VALUE v_info)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  return INT2NUM(snd_seq_query_subscribe_get_type(info));
}

/** call-seq: client = id

Set the client id, to initiate a query.

Parameters:
[client]  client id

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers() and  RRTS::Driver::AlsaQuerySubscribe_i#client
*/
static VALUE
wrap_snd_seq_query_subscribe_set_client(VALUE v_info, VALUE v_id)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  snd_seq_query_subscribe_set_client(info, NUM2INT(v_id));
  return Qnil;
}

/** call-seq: index = id

Set the index, to initiate a query.

Parameters:
[index]  index to be queried

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers() and  RRTS::Driver::AlsaQuerySubscribe_i#index
*/
static VALUE
wrap_snd_seq_query_subscribe_set_index(VALUE v_info, VALUE v_id)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  snd_seq_query_subscribe_set_index(info, NUM2INT(v_id));
  return Qnil;
}

/** call-seq: port = id

Set the port id, to initiate a query.

Parameters:
[port]  port id to be queried

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers() and  RRTS::Driver::AlsaQuerySubscribe_i#port
*/
static VALUE
wrap_snd_seq_query_subscribe_set_port(VALUE v_info, VALUE v_id)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  snd_seq_query_subscribe_set_port(info, NUM2INT(v_id));
  return Qnil;
}

/** call-seq: root = address_specification

Set the client and port id, to initiate a query.

Parameters:
[address_specification]  a single MidiPort, or a combination op clientid and portid

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers() and  RRTS::Driver::AlsaQuerySubscribe_i#root
*/
static VALUE
wrap_snd_seq_query_subscribe_set_root(int argc, VALUE *argv, VALUE v_info)
{
  FETCH_ADDRESSES();
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  const snd_seq_addr_t root = { NUM2INT(v_clientid), NUM2INT(v_portid) };
  snd_seq_query_subscribe_set_root(info, &root);
  return Qnil;
}

/** call-seq: type = int

Set the type of query

Parameters:
[type]  either SND_SEQ_QUERY_SUBS_READ or else SND_SEQ_QUERY_SUBS_WRITE

See also:
    RRTS::Driver::AlsaSequencer_i#query_port_subscribers() and  RRTS::Driver::AlsaQuerySubscribe_i#type
*/
static VALUE
wrap_snd_seq_query_subscribe_set_type(VALUE v_info, VALUE v_id)
{
  snd_seq_query_subscribe_t *info;
  Data_Get_Struct(v_info, snd_seq_query_subscribe_t, info);
  const int tp = NUM2INT(v_id);
  if (tp != SND_SEQ_QUERY_SUBS_READ && tp != SND_SEQ_QUERY_SUBS_WRITE)
    RAISE_MIDI_ERROR("bad type %d", tp);
  snd_seq_query_subscribe_set_type(info, (snd_seq_query_subs_type_t)tp);
  return Qnil;
}

void
alsa_query_subscribe_init()
{
  WRAP_CONSTANT(SND_SEQ_QUERY_SUBS_READ);
  WRAP_CONSTANT(SND_SEQ_QUERY_SUBS_WRITE);
  alsaQuerySubscribeClass = rb_define_class_under(alsaDriver, "AlsaQuerySubscribe_i", rb_cObject);
  rb_define_method(alsaQuerySubscribeClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_copy_to), -1);
  rb_define_method(alsaQuerySubscribeClass, "client", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_get_client), 0);
  rb_define_method(alsaQuerySubscribeClass, "port", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_get_port), 0);
  rb_define_method(alsaQuerySubscribeClass, "root", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_get_root), 0);
  rb_define_method(alsaQuerySubscribeClass, "type", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_get_type), 0);
  rb_define_method(alsaQuerySubscribeClass, "index", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_get_index), 0);
  rb_define_method(alsaQuerySubscribeClass, "num_subs", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_get_num_subs), 0);
  rb_define_method(alsaQuerySubscribeClass, "addr", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_get_addr), 0);
  rb_define_method(alsaQuerySubscribeClass, "queue", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_get_queue), 0);
  rb_define_method(alsaQuerySubscribeClass, "exclusive?", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_get_exclusive), 0);
  rb_define_method(alsaQuerySubscribeClass, "time_update?", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_get_time_update), 0);
  rb_define_method(alsaQuerySubscribeClass, "time_real?", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_get_time_real), 0);
  rb_define_method(alsaQuerySubscribeClass, "client=", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_set_client), 1);
  rb_define_method(alsaQuerySubscribeClass, "port=", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_set_port), 1);
  rb_define_method(alsaQuerySubscribeClass, "root=", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_set_root), -1);
  rb_define_method(alsaQuerySubscribeClass, "type=", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_set_type), 1);
  rb_define_method(alsaQuerySubscribeClass, "index=", RUBY_METHOD_FUNC(wrap_snd_seq_query_subscribe_set_index), 1);
}
