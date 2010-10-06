
#pragma implementation
#include "alsa_client_pool.h"

#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaClientPoolClass;

/** Document-method: RRTS::Driver::AlsaClientPool_i#copy_to
call-seq:  copy_to([other=nil]) -> clone

Parameters:
[other] if given copy +self+ to it, otherwise create a copy and return it. This copy need
        not be freed.
*/
ALSA_MIDI_COPY_TO_TEMPLATE(client_pool, ClientPool)

/** call-seq: client() -> int

Returns: the client id
*/
static VALUE
wrap_snd_seq_client_pool_get_client(VALUE v_pool)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  return INT2NUM(snd_seq_client_pool_get_client(pool));
}

/** call-seq: output_pool() -> int

Returns: the output pool size. This is the total kernelspace reserved for this client for
buffering events sent to other clients.
This is a pool in the sense that ports share this space. If a single port fills the
outputpool then other ports cannot write either.
*/
static VALUE
wrap_snd_seq_client_pool_get_output_pool(VALUE v_pool)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  return UINT2NUM(snd_seq_client_pool_get_output_pool(pool));
}

/** call-seq: input_pool() -> int

Returns: Get the input pool size. This is the total amount of kernelspace
for events waiting to be read by a client.
*/
static VALUE
wrap_snd_seq_client_pool_get_input_pool(VALUE v_pool)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  return UINT2NUM(snd_seq_client_pool_get_input_pool(pool));
}

/** call-seq: output_room() -> int

Returns: the output room size
*/
static VALUE
wrap_snd_seq_client_pool_get_output_room(VALUE v_pool)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  return UINT2NUM(snd_seq_client_pool_get_output_room(pool));
}

/** call-seq: output_free() -> int

Returns: the available free space on the output pool in bytes
*/
static VALUE
wrap_snd_seq_client_pool_get_output_free(VALUE v_pool)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  return UINT2NUM(snd_seq_client_pool_get_output_free(pool));
}

/** call-seq: input_free() -> int

Returns: the available size in bytes on the input pool
*/
static VALUE
wrap_snd_seq_client_pool_get_input_free(VALUE v_pool)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  return UINT2NUM(snd_seq_client_pool_get_input_free(pool));
}

/** call-seq: output_pool = size

Set the output pool size
*/
static VALUE
wrap_snd_seq_client_pool_set_output_pool(VALUE v_pool, VALUE v_sz)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  snd_seq_client_pool_set_output_pool(pool, NUM2UINT(v_sz));
  return Qnil;
}

/** call-seq:  input_pool = size

Set the input pool size
*/
static VALUE
wrap_snd_seq_client_pool_set_input_pool(VALUE v_pool, VALUE v_sz)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  snd_seq_client_pool_set_input_pool(pool, NUM2UINT(v_sz));
  return Qnil;
}

/** call-seq  output_room = size

Set the output room size. According to Eugene this is the watermark to wake up a
client that got blocked when writing data, because the output pool was full.

*/
static VALUE
wrap_snd_seq_client_pool_set_output_room(VALUE v_pool, VALUE v_sz)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  snd_seq_client_pool_set_output_room(pool, NUM2UINT(v_sz));
  return Qnil;
}

void
alsa_client_pool_init()
{
  /** Document-class: RRTS::Driver::AlsaClientPool_i

  I have no idea what the use of all this is.
  Perhaps a clientpool is the total amount of memory that can be allocated to buffers and queues
  for some client.
*/
  alsaClientPoolClass = rb_define_class_under(alsaDriver, "AlsaClientPool_i", rb_cObject);
  rb_define_method(alsaClientPoolClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_client_pool_copy_to), -1);
  rb_define_method(alsaClientPoolClass, "client", RUBY_METHOD_FUNC(wrap_snd_seq_client_pool_get_client), 0);
  rb_define_method(alsaClientPoolClass, "output_pool", RUBY_METHOD_FUNC(wrap_snd_seq_client_pool_get_output_pool), 0);
  rb_define_method(alsaClientPoolClass, "output_pool=", RUBY_METHOD_FUNC(wrap_snd_seq_client_pool_set_output_pool), 1);
  rb_define_method(alsaClientPoolClass, "output_room", RUBY_METHOD_FUNC(wrap_snd_seq_client_pool_get_output_room), 0);
  rb_define_method(alsaClientPoolClass, "output_room=", RUBY_METHOD_FUNC(wrap_snd_seq_client_pool_set_output_room), 1);
  rb_define_method(alsaClientPoolClass, "output_free", RUBY_METHOD_FUNC(wrap_snd_seq_client_pool_get_output_free), 0);
  rb_define_method(alsaClientPoolClass, "input_pool", RUBY_METHOD_FUNC(wrap_snd_seq_client_pool_get_input_pool), 0);
  rb_define_method(alsaClientPoolClass, "input_pool=", RUBY_METHOD_FUNC(wrap_snd_seq_client_pool_set_input_pool), 1);
  rb_define_method(alsaClientPoolClass, "input_free", RUBY_METHOD_FUNC(wrap_snd_seq_client_pool_get_input_free), 0);
}
