
// If changed do:         make
// To create Makefile:    ruby ./extruby.rb

#pragma implementation
#include "alsa_system_info.h"
#include "alsa_midi.h"
#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaSystemInfoClass;

/*
void    snd_seq_system_info_copy (snd_seq_system_info_t *dst, const snd_seq_system_info_t *src)
Copy one snd_seq_system_info_t to another.
*/
static VALUE
wrap_snd_seq_system_info_copy_to(int argc, VALUE *argv, VALUE v_sysinfo)
{
  VALUE v_dst;
  rb_scan_args(argc, argv, "01", &v_dst);
  VALUE retval = v_sysinfo;
  snd_seq_system_info_t *sysinfo, *dst;
  if (NIL_P(v_dst))
    {
      const int r = snd_seq_system_info_malloc(&dst);
      if (r < 0) RAISE_MIDI_ERROR("allocating system_info", r);
      v_dst = Data_Wrap_Struct(alsaSystemInfoClass, 0/*mark*/, snd_seq_system_info_free/*free*/, dst);
      retval = v_dst;
    }
  Data_Get_Struct(v_sysinfo, snd_seq_system_info_t, sysinfo);
  Data_Get_Struct(v_dst, snd_seq_system_info_t, dst);
  snd_seq_system_info_copy(dst, sysinfo);
  return retval;
}

/*
int     snd_seq_system_info_get_queues (const snd_seq_system_info_t *info)
Get maximum number of queues.
*/
static VALUE
wrap_snd_seq_system_info_get_queues(VALUE v_info)
{
  snd_seq_system_info_t *info;
  Data_Get_Struct(v_info, snd_seq_system_info_t, info);
  return INT2NUM(snd_seq_system_info_get_queues(info));
}

/*
int     snd_seq_system_info_get_clients (const snd_seq_system_info_t *info)
Get maximum number of clients.
*/
static VALUE
wrap_snd_seq_system_info_get_clients(VALUE v_info)
{
  snd_seq_system_info_t *info;
  Data_Get_Struct(v_info, snd_seq_system_info_t, info);
  return INT2NUM(snd_seq_system_info_get_clients(info));
}

/*
int     snd_seq_system_info_get_ports (const snd_seq_system_info_t *info)
Get maximum number of ports.
*/
static VALUE
wrap_snd_seq_system_info_get_ports(VALUE v_info)
{
  snd_seq_system_info_t *info;
  Data_Get_Struct(v_info, snd_seq_system_info_t, info);
  return INT2NUM(snd_seq_system_info_get_ports(info));
}

/*
int     snd_seq_system_info_get_channels (const snd_seq_system_info_t *info)
Get maximum number of channels.
*/
static VALUE
wrap_snd_seq_system_info_get_channels(VALUE v_info)
{
  snd_seq_system_info_t *info;
  Data_Get_Struct(v_info, snd_seq_system_info_t, info);
  return INT2NUM(snd_seq_system_info_get_channels(info));
}

/*
int     snd_seq_system_info_get_cur_clients (const snd_seq_system_info_t *info)
Get the current number of clients.
*/
static VALUE
wrap_snd_seq_system_info_get_cur_clients(VALUE v_info)
{
  snd_seq_system_info_t *info;
  Data_Get_Struct(v_info, snd_seq_system_info_t, info);
  return INT2NUM(snd_seq_system_info_get_cur_clients(info));
}

/*
int     snd_seq_system_info_get_cur_queues (const snd_seq_system_info_t *info)
Get the current number of queues.
*/
static VALUE
wrap_snd_seq_system_info_get_cur_queues(VALUE v_info)
{
  snd_seq_system_info_t *info;
  Data_Get_Struct(v_info, snd_seq_system_info_t, info);
  return INT2NUM(snd_seq_system_info_get_cur_queues(info));
}

void
alsa_system_info_init()
{
  alsaSystemInfoClass = rb_define_class_under(alsaDriver, "AlsaSystemInfo_i", rb_cObject);
  rb_define_method(alsaSystemInfoClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_system_info_copy_to), -1);
  rb_define_method(alsaSystemInfoClass, "clients",
                   RUBY_METHOD_FUNC(wrap_snd_seq_system_info_get_clients), 0);
  rb_define_method(alsaSystemInfoClass, "cur_clients",
                   RUBY_METHOD_FUNC(wrap_snd_seq_system_info_get_cur_clients), 0);
  rb_define_method(alsaSystemInfoClass, "ports",
                   RUBY_METHOD_FUNC(wrap_snd_seq_system_info_get_ports), 0);
  rb_define_method(alsaSystemInfoClass, "queues",
                   RUBY_METHOD_FUNC(wrap_snd_seq_system_info_get_queues), 0);
  rb_define_method(alsaSystemInfoClass, "cur_queues",
                   RUBY_METHOD_FUNC(wrap_snd_seq_system_info_get_cur_queues), 0);
  rb_define_method(alsaSystemInfoClass, "channels",
                   RUBY_METHOD_FUNC(wrap_snd_seq_system_info_get_channels), 0);
}
