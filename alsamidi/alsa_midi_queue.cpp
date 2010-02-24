
#pragma implementation

#include "alsa_midi_queue.h"
#include "alsa_midi.h"

#if defined(DUMP_API)
#define DUMP_STREAM stderr
#endif

#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaQueueInfoClass, alsaQueueTempoClass, alsaQueueStatusClass;

// self QueueTempo#copy_to tempo
static VALUE
wrap_snd_seq_queue_tempo_copy_to(VALUE v_queue_tempo, VALUE v_dst)
{
  snd_seq_queue_tempo_t *tempo, *dst;
  Data_Get_Struct(v_queue_tempo, snd_seq_queue_tempo_t, tempo);
  Data_Get_Struct(v_dst, snd_seq_queue_tempo_t, dst);
  snd_seq_queue_tempo_copy(dst, tempo);
  return v_queue_tempo;
}

// self QueueStatus#copy_to status
static VALUE
wrap_snd_seq_queue_status_copy_to(VALUE v_queue_status, VALUE v_dst)
{
  snd_seq_queue_status_t *status, *dst;
  Data_Get_Struct(v_queue_status, snd_seq_queue_status_t, status);
  Data_Get_Struct(v_dst, snd_seq_queue_status_t, dst);
  snd_seq_queue_status_copy(dst, status);
  return v_queue_status;
}

// self QueueInfo#copy_to info
static VALUE
wrap_snd_seq_queue_info_copy_to(VALUE v_queue_info, VALUE v_dst)
{
  snd_seq_queue_info_t *queue_info, *dst;
  Data_Get_Struct(v_queue_info, snd_seq_queue_info_t, queue_info);
  Data_Get_Struct(v_dst, snd_seq_queue_info_t, dst);
  snd_seq_queue_info_copy(dst, queue_info);
  return v_queue_info;
}

// QueueInfo#flags= flags
static VALUE
wrap_snd_seq_queue_info_set_flags(VALUE v_qi, VALUE v_flags)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  snd_seq_queue_info_set_flags(qi, NUM2UINT(v_flags));
  return Qnil;
}

// QueueInfo#locked= bool
static VALUE
wrap_snd_seq_queue_info_set_locked(VALUE v_qi, VALUE v_locked)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  snd_seq_queue_info_set_locked(qi, BOOL2INT(v_locked));
  return Qnil;
}

// QueueInfo#name=
static VALUE
wrap_snd_seq_queue_info_set_name(VALUE v_qi, VALUE v_name)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_queue_info_set_name(%p, %s)\n", qi, RSTRING_PTR(v_name));
#endif
  snd_seq_queue_info_set_name(qi, StringValuePtr(v_name));
  return Qnil;
}

// int QueueInfo#queue
static VALUE
wrap_snd_seq_queue_info_get_queue(VALUE v_qi)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  return INT2NUM(snd_seq_queue_info_get_queue(qi));
}

// int QueueInfo#flags
static VALUE
wrap_snd_seq_queue_info_get_flags(VALUE v_qi)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  return UINT2NUM(snd_seq_queue_info_get_flags(qi));
}

// string QueueInfo#name
static VALUE
wrap_snd_seq_queue_info_get_name(VALUE v_qi)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  return rb_str_new2(snd_seq_queue_info_get_name(qi));
}

/* int QueueInfo#owner
 returns the client (id)
*/
static VALUE
wrap_snd_seq_queue_info_get_owner(VALUE v_qi)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  return INT2NUM(snd_seq_queue_info_get_owner(qi));
}

/* bool QueueInfo#locked?
*/
static VALUE
wrap_snd_seq_queue_info_get_locked(VALUE v_qi)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  return INT2BOOL(snd_seq_queue_info_get_locked(qi));
}

/* QueueInfo.owner= ownerid

Set the owner client id of a queue_info container.

Parameters:
owner   client id
*/
static VALUE
wrap_snd_seq_queue_info_set_owner(VALUE v_qi, VALUE v_owner_clientid)
{
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  #if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_queue_info_set_owner(%p, %d)\n", qi, NUM2INT(v_owner_clientid));
  #endif
  snd_seq_queue_info_set_owner(qi, NUM2INT(v_owner_clientid));
  return Qnil;
}

/*
int QueueTempo#ppq

Get the ppq of a queue_status container.

Returns:
  ppq value
*/
static VALUE
wrap_snd_seq_queue_tempo_get_ppq(VALUE v_tempo)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  return INT2NUM(snd_seq_queue_tempo_get_ppq(tempo));
}

/* int QueueTempo#queue

Get the queue id of a queue_status container.

Returns:
  queue id
*/

static VALUE
wrap_snd_seq_queue_tempo_get_queue(VALUE v_tempo)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  return INT2NUM(snd_seq_queue_tempo_get_queue(tempo));
}

/* int QueueTempo#skew

Get the timer skew value of a queue_status container.

Returns:
  timer skew value
*/
static VALUE
wrap_snd_seq_queue_tempo_get_skew(VALUE v_tempo)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  return UINT2NUM(snd_seq_queue_tempo_get_skew(tempo));
}

/*
 int QueueTempo#skew_base

Get the timer skew base value of a queue_status container.

Returns:
  timer skew base value
*/
static VALUE
wrap_snd_seq_queue_tempo_get_skew_base(VALUE v_tempo)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  return UINT2NUM(snd_seq_queue_tempo_get_skew_base(tempo));
}

/*
 int QueueTempo#tempo

Get the tempo of a queue_status container.

Returns:
  tempo value
*/
static VALUE
wrap_snd_seq_queue_tempo_get_tempo(VALUE v_tempo)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  return UINT2NUM(snd_seq_queue_tempo_get_tempo(tempo));
}

/*
 QueueTempo.ppq= ppq

Set the ppq of a queue_status container.

Parameters:
ppq     ppq value
*/
static VALUE
wrap_snd_seq_queue_tempo_set_ppq(VALUE v_tempo, VALUE v_ppq)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  snd_seq_queue_tempo_set_ppq(tempo, NUM2INT(v_ppq));
  return Qnil;
}

// QueueTempo#skew= skew
static VALUE
wrap_snd_seq_queue_tempo_set_skew(VALUE v_tempo, VALUE v_skew)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  snd_seq_queue_tempo_set_skew(tempo, NUM2UINT(v_skew));
  return Qnil;
}

// QueueTempo#skew_base = skew_base
static VALUE
wrap_snd_seq_queue_tempo_set_skew_base(VALUE v_tempo, VALUE v_skew)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  snd_seq_queue_tempo_set_skew_base(tempo, NUM2UINT(v_skew));
  return Qnil;
}

// QueueTempo#tempo=
static VALUE
wrap_snd_seq_queue_tempo_set_tempo(VALUE v_tempo, VALUE v_val)
{
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
  snd_seq_queue_tempo_set_tempo(tempo, NUM2UINT(v_val));
  return Qnil;
}

// int QueueStatus.queue
static VALUE
wrap_snd_seq_queue_status_get_queue(VALUE v_status)
{
  snd_seq_queue_status_t *status;
  Data_Get_Struct(v_status, snd_seq_queue_status_t, status);
  return INT2NUM(snd_seq_queue_status_get_queue(status));
}

/* int QueueStatus#events
 nr of events remaining in queue
*/
static VALUE
wrap_snd_seq_queue_status_get_events(VALUE v_status)
{
  snd_seq_queue_status_t *status;
  Data_Get_Struct(v_status, snd_seq_queue_status_t, status);
  return INT2NUM(snd_seq_queue_status_get_events(status));
}

// int QueueStatus#tick_time
static VALUE
wrap_snd_seq_queue_status_get_tick_time(VALUE v_status)
{
  snd_seq_queue_status_t *status;
  Data_Get_Struct(v_status, snd_seq_queue_status_t, status);
  return UINT2NUM(snd_seq_queue_status_get_tick_time(status));
}

// secs, nsec QueueStatus#real_time
static VALUE
wrap_snd_seq_queue_status_get_real_time(VALUE v_status)
{
  snd_seq_queue_status_t *status;
  Data_Get_Struct(v_status, snd_seq_queue_status_t, status);
  const snd_seq_real_time * const t = snd_seq_queue_status_get_real_time(status);
  return rb_ary_new3(2, UINT2NUM(t->tv_sec), UINT2NUM(t->tv_nsec));
}

// int QueueStatus#status
static VALUE
wrap_snd_seq_queue_status_get_status(VALUE v_status)
{
  snd_seq_queue_status_t *status;
  Data_Get_Struct(v_status, snd_seq_queue_status_t, status);
  return UINT2NUM(snd_seq_queue_status_get_status(status));
}

void
alsa_midi_queue_init()
{
  alsaQueueInfoClass = rb_define_class_under(alsaDriver, "AlsaQueueInfo_i", rb_cObject);
  alsaQueueTempoClass = rb_define_class_under(alsaDriver, "AlsaQueueTempo_i", rb_cObject);
  alsaQueueStatusClass = rb_define_class_under(alsaDriver, "AlsaQueueStatus_i", rb_cObject);

  rb_define_method(alsaQueueTempoClass, "tempo=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_set_tempo), 1);
  rb_define_method(alsaQueueTempoClass, "ppq=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_set_ppq), 1);
  rb_define_method(alsaQueueTempoClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_copy_to), 1);
  rb_define_method(alsaQueueTempoClass, "skew=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_set_skew), 1);
  rb_define_method(alsaQueueTempoClass, "skew_base=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_set_skew_base), 1);
  rb_define_method(alsaQueueTempoClass, "skew_base", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_get_skew_base), 0);
  rb_define_method(alsaQueueTempoClass, "skew", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_get_skew), 0);
  rb_define_method(alsaQueueTempoClass, "ppq", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_get_ppq), 0);
  rb_define_method(alsaQueueTempoClass, "tempo", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_get_tempo), 0);
  rb_define_method(alsaQueueTempoClass, "queue", RUBY_METHOD_FUNC(wrap_snd_seq_queue_tempo_get_queue), 0);

  rb_define_method(alsaQueueInfoClass, "flags=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_set_flags), 1);
  rb_define_method(alsaQueueInfoClass, "locked=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_set_locked), 1);
  rb_define_method(alsaQueueInfoClass, "name=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_set_name), 1);
  rb_define_method(alsaQueueInfoClass, "owner=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_set_owner), 1);
  rb_define_method(alsaQueueInfoClass, "queue", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_get_queue), 0);
  rb_define_method(alsaQueueInfoClass, "name", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_get_name), 0);
  rb_define_method(alsaQueueInfoClass, "owner", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_get_owner), 0);
  rb_define_method(alsaQueueInfoClass, "locked?", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_get_locked), 0);
  rb_define_method(alsaQueueInfoClass, "flags", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_get_flags), 0);
  rb_define_method(alsaQueueInfoClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_queue_info_copy_to), 1);

  rb_define_method(alsaQueueStatusClass, "queue", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_get_queue), 0);
  rb_define_method(alsaQueueStatusClass, "events", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_get_events), 0);
  rb_define_method(alsaQueueStatusClass, "tick_time", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_get_tick_time), 0);
  rb_define_method(alsaQueueStatusClass, "real_time", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_get_real_time), 0);
  rb_define_method(alsaQueueStatusClass, "status", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_get_status), 0);
  rb_define_method(alsaQueueStatusClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_queue_status_copy_to), 1);
}
