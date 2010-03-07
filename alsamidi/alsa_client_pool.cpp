
#pragma implementation
#include "alsa_client_pool.h"

#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaClientPoolClass;

/*
void    snd_seq_client_pool_copy (snd_seq_client_pool_t *dst, const snd_seq_client_pool_t *src)
copy one snd_seq_client_pool_t to another
*/
static VALUE
wrap_snd_seq_client_pool_copy_to(int argc, VALUE *argv, VALUE v_pool)
{
  VALUE v_dst;
  rb_scan_args(argc, argv, "01", &v_dst);
  VALUE retval = v_pool;
  snd_seq_client_pool_t *pool, *dst;
  if (NIL_P(v_dst))
  {
    const int r = snd_seq_client_pool_malloc(&dst);
    if (r < 0) RAISE_MIDI_ERROR("allocating client_pool", r);
    v_dst = Data_Wrap_Struct(alsaClientPoolClass, 0/*mark*/, snd_seq_client_pool_free/*free*/, dst);
    retval = v_dst;
  }
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  Data_Get_Struct(v_dst, snd_seq_client_pool_t, dst);
  snd_seq_client_pool_copy(dst, pool);
  return retval;
}

/*
int     snd_seq_client_pool_get_client (const snd_seq_client_pool_t *info)
Get the client id of a queue_info container.
*/
static VALUE
wrap_snd_seq_client_pool_get_client(VALUE v_pool)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  return INT2NUM(snd_seq_client_pool_get_client(pool));
}

/*
size_t  snd_seq_client_pool_get_output_pool (const snd_seq_client_pool_t *info)
Get the output pool size of a queue_info container.
*/
static VALUE
wrap_snd_seq_client_pool_get_output_pool(VALUE v_pool)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  return UINT2NUM(snd_seq_client_pool_get_output_pool(pool));
}

/*
size_t  snd_seq_client_pool_get_input_pool (const snd_seq_client_pool_t *info)
Get the input pool size of a queue_info container.
*/
static VALUE
wrap_snd_seq_client_pool_get_input_pool(VALUE v_pool)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  return UINT2NUM(snd_seq_client_pool_get_input_pool(pool));
}

/*
size_t  snd_seq_client_pool_get_output_room (const snd_seq_client_pool_t *info)
Get the output room size of a queue_info container.
*/
static VALUE
wrap_snd_seq_client_pool_get_output_room(VALUE v_pool)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  return UINT2NUM(snd_seq_client_pool_get_output_room(pool));
}

/*
size_t  snd_seq_client_pool_get_output_free (const snd_seq_client_pool_t *info)
Get the available size on output pool of a queue_info container.
*/
static VALUE
wrap_snd_seq_client_pool_get_output_free(VALUE v_pool)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  return UINT2NUM(snd_seq_client_pool_get_output_free(pool));
}

/*
size_t  snd_seq_client_pool_get_input_free (const snd_seq_client_pool_t *info)
Get the available size on input pool of a queue_info container.
*/
static VALUE
wrap_snd_seq_client_pool_get_input_free(VALUE v_pool)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  return UINT2NUM(snd_seq_client_pool_get_input_free(pool));
}

/*
void    snd_seq_client_pool_set_output_pool (snd_seq_client_pool_t *info, size_t size)
Set the output pool size of a queue_info container.
*/
static VALUE
wrap_snd_seq_client_pool_set_output_pool(VALUE v_pool, VALUE v_sz)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  snd_seq_client_pool_set_output_pool(pool, NUM2UINT(v_sz));
  return Qnil;
}

/*
void    snd_seq_client_pool_set_input_pool (snd_seq_client_pool_t *info, size_t size)
Set the input pool size of a queue_info container.
*/
static VALUE
wrap_snd_seq_client_pool_set_input_pool(VALUE v_pool, VALUE v_sz)
{
  snd_seq_client_pool_t *pool;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  snd_seq_client_pool_set_input_pool(pool, NUM2UINT(v_sz));
  return Qnil;
}

/*
void    snd_seq_client_pool_set_output_room (snd_seq_client_pool_t *info, size_t size)
Set the output room size of a queue_info container.
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
