
#pragma implementation
#include "alsa_remove.h"
#include "alsa_midi_client.h"

#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaRemoveEventsClass;

/* void    snd_seq_remove_events_free (snd_seq_remove_events_t *ptr)
frees a previously allocated snd_seq_remove_events_t
AUTOM
*/

/* copy AlsaRemoveEvents_i#copy_to dst
copy one snd_seq_remove_events_t to another
*/
static VALUE
wrap_snd_seq_remove_events_copy_to(int argc, VALUE *argv, VALUE v_rmp)
{
  VALUE v_dst;
  rb_scan_args(argc, argv, "01", &v_dst);
  VALUE retval = v_rmp;
  snd_seq_remove_events_t *rmp, *dst;
  if (NIL_P(v_dst))
  {
    const int r = snd_seq_remove_events_malloc(&dst);
    if (r < 0) RAISE_MIDI_ERROR("allocating remove_events", r);
    v_dst = Data_Wrap_Struct(alsaRemoveEventsClass, 0/*mark*/, snd_seq_remove_events_free/*free*/, dst);
    retval = v_dst;
  }
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  Data_Get_Struct(v_dst, snd_seq_remove_events_t, dst);
  snd_seq_remove_events_copy(dst, rmp);
  return retval;
}

/* int    AlsaRemoveEvents_i#condition
Get the removal condition bits.
*/
static VALUE
wrap_snd_seq_remove_events_get_condition(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  return UINT2NUM(snd_seq_remove_events_get_condition(rmp));
}

/*
int     snd_seq_remove_events_get_queue (const snd_seq_remove_events_t *info)
Get the queue as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_get_queue(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  return INT2NUM(snd_seq_remove_events_get_queue(rmp));
}

/*
int AlsaRemoveEvents_i#time_tick
Get the event timestamp as removal condition.
*/
static VALUE
ARE_get_time_tick(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  return UINT2NUM(snd_seq_remove_events_get_time(rmp)->tick);
}

/*
sec, nsec AlsaRemoveEvents_i#time_real
Get the event timestamp as removal condition
*/
static VALUE
ARE_get_time_real(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  const snd_seq_timestamp_t * const tm = snd_seq_remove_events_get_time(rmp);
  return rb_ary_new3(2, UINT2NUM(tm->time.tv_sec), UINT2NUM(tm->time.tv_nsec));
}

/*
clientid, portid AlsaRemoveEvents_i#dest
Get the event destination address as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_get_dest(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  const snd_seq_addr_t* const a = snd_seq_remove_events_get_dest(rmp);
  return rb_ary_new3(2, UINT2NUM(a->client), UINT2NUM(a->port));
}

/*int    AlsaRemoveEvents_i#channel
Get the event channel as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_get_channel(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  return INT2NUM(snd_seq_remove_events_get_channel(rmp));
}

/*
int     snd_seq_remove_events_get_event_type (const snd_seq_remove_events_t *info)
Get the event type as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_get_event_type(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  return INT2NUM(snd_seq_remove_events_get_event_type(rmp));
}

/*
int     snd_seq_remove_events_get_tag (const snd_seq_remove_events_t *info)
Get the event tag id as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_get_tag(VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  return INT2NUM(snd_seq_remove_events_get_tag(rmp));
}

/*
void    snd_seq_remove_events_set_condition (snd_seq_remove_events_t *info, unsigned int flags)
Set the removal condition bits.
*/
static VALUE
wrap_snd_seq_remove_events_set_condition(VALUE v_rmp, VALUE v_flags)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  snd_seq_remove_events_set_condition(rmp, NUM2UINT(v_flags));
  return Qnil;
}

/*
void    snd_seq_remove_events_set_queue (snd_seq_remove_events_t *info, int queue)
Set the queue as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_set_queue(VALUE v_rmp, VALUE v_queue)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  RRTS_DEREF_DIRTY(v_queue, @id);
  snd_seq_remove_events_set_queue(rmp, NUM2INT(v_queue));
  return Qnil;
}

/*
void    snd_seq_remove_events_set_time (snd_seq_remove_events_t *info, const snd_seq_timestamp_t *time)
Set the timestamp as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_set_time(int argc, VALUE *argv, VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  VALUE v_sec, v_nsec;
  rb_scan_args(argc, argv, "11", &v_sec, &v_nsec);
  snd_seq_timestamp_t time;
  if (NIL_P(v_nsec))
    {
      if (FIXNUM_P(v_sec))
          time.tick = NUM2UINT(v_sec);
      else
        {
          v_sec = rb_check_array_type(v_sec);
          if (!RTEST(v_sec)) RAISE_MIDI_ERROR_FMT0("API call error: bad time format");
          time.time.tv_sec = NUM2UINT(rb_ary_entry(v_sec, 0));
          time.time.tv_nsec = NUM2UINT(rb_ary_entry(v_sec, 1));
        }
    }
  else
    {
      time.time.tv_sec = NUM2UINT(v_sec);
      time.time.tv_nsec = NUM2UINT(v_nsec);
    }
  snd_seq_remove_events_set_time(rmp, &time);
  return Qnil;
}

static VALUE
ARE_set_time_real(int argc, VALUE *argv, VALUE v_rmp)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  VALUE v_sec, v_nsec;
  rb_scan_args(argc, argv, "11", &v_sec, &v_nsec);
  if (NIL_P(v_nsec))
  {
    v_sec = rb_check_array_type(v_sec);
    if (!RTEST(v_sec)) RAISE_MIDI_ERROR_FMT0("API call error: realtime needs sec+nsec tuple");
    v_nsec = rb_ary_entry(v_sec, 1);
    v_sec = rb_ary_entry(v_sec, 0);
  }
  snd_seq_timestamp_t time;
  time.time.tv_sec = NUM2UINT(v_sec);
  time.time.tv_nsec = NUM2UINT(v_nsec);
  snd_seq_remove_events_set_time(rmp, &time);
  return Qnil;
}

static VALUE
ARE_set_time_tick(VALUE v_rmp, VALUE v_ticks)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  snd_seq_timestamp_t time;
  time.tick = NUM2UINT(v_ticks);
  snd_seq_remove_events_set_time(rmp, &time);
  return Qnil;
}

/*
void    snd_seq_remove_events_set_dest (snd_seq_remove_events_t *info, const snd_seq_addr_t *addr)
Set the destination address as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_set_dest(int argc, VALUE *argv, VALUE v_rmp)
{
  FETCH_ADDRESSES();
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  snd_seq_addr_t a;
  a.client = NUM2INT(v_clientid);
  a.port = NUM2INT(v_portid);
  snd_seq_remove_events_set_dest(rmp, &a);
  return Qnil;
}

/*
void    snd_seq_remove_events_set_channel (snd_seq_remove_events_t *info, int channel)
Set the channel as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_set_channel(VALUE v_rmp, VALUE v_ch)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  snd_seq_remove_events_set_channel(rmp, NUM2INT(v_ch));
  return Qnil;
}

/*
void    snd_seq_remove_events_set_event_type (snd_seq_remove_events_t *info, int type)
Set the event type as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_set_event_type(VALUE v_rmp, VALUE v_evtype)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  snd_seq_remove_events_set_event_type(rmp, NUM2INT(v_evtype));
  return Qnil;
}

/*
void    snd_seq_remove_events_set_tag (snd_seq_remove_events_t *info, int tag)
Set the event tag as removal condition.
*/
static VALUE
wrap_snd_seq_remove_events_set_tag(VALUE v_rmp, VALUE v_tag)
{
  snd_seq_remove_events_t *rmp;
  Data_Get_Struct(v_rmp, snd_seq_remove_events_t, rmp);
  snd_seq_remove_events_set_tag(rmp, NUM2INT(v_tag));
  return Qnil;
}

void
alsa_remove_init()
{
  alsaRemoveEventsClass = rb_define_class_under(alsaDriver, "AlsaRemoveEvents_i", rb_cObject);

  //arg1 for snd_seq_ev_is....type
  WRAP_CONSTANT(SND_SEQ_REMOVE_INPUT);
  WRAP_CONSTANT(SND_SEQ_REMOVE_OUTPUT);
  WRAP_CONSTANT(SND_SEQ_REMOVE_DEST);
  WRAP_CONSTANT(SND_SEQ_REMOVE_DEST_CHANNEL);
  WRAP_CONSTANT(SND_SEQ_REMOVE_TIME_BEFORE);
  WRAP_CONSTANT(SND_SEQ_REMOVE_TIME_AFTER);
  WRAP_CONSTANT(SND_SEQ_REMOVE_TIME_TICK);
  WRAP_CONSTANT(SND_SEQ_REMOVE_EVENT_TYPE);
  WRAP_CONSTANT(SND_SEQ_REMOVE_TAG_MATCH);
  WRAP_CONSTANT(SND_SEQ_REMOVE_IGNORE_OFF);

  rb_define_method(alsaRemoveEventsClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_copy_to), -1);
  rb_define_method(alsaRemoveEventsClass, "condition",
                   RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_condition), 0);
  rb_define_method(alsaRemoveEventsClass, "queue",
                   RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_queue), 0);
  rb_define_method(alsaRemoveEventsClass, "time_tick",
                                    RUBY_METHOD_FUNC(ARE_get_time_tick), 0);
  rb_define_method(alsaRemoveEventsClass, "time_real", RUBY_METHOD_FUNC(ARE_get_time_real), 0);
  rb_define_method(alsaRemoveEventsClass, "dest", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_dest), 0);
  rb_define_method(alsaRemoveEventsClass, "channel", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_channel), 0);
  rb_define_method(alsaRemoveEventsClass, "event_type", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_event_type), 0);
  rb_define_method(alsaRemoveEventsClass, "type", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_event_type), 0);
  rb_define_method(alsaRemoveEventsClass, "tag", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_get_tag), 0);
  rb_define_method(alsaRemoveEventsClass, "condition=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_condition), 1);
  rb_define_method(alsaRemoveEventsClass, "queue=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_queue), 1);
  rb_define_method(alsaRemoveEventsClass, "time=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_time), -1);
  rb_define_method(alsaRemoveEventsClass, "time_real=", RUBY_METHOD_FUNC(ARE_set_time_real), -1);
  rb_define_method(alsaRemoveEventsClass, "time_tick=", RUBY_METHOD_FUNC(ARE_set_time_tick), 1);
  rb_define_method(alsaRemoveEventsClass, "dest=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_dest), -1);
  rb_define_method(alsaRemoveEventsClass, "channel=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_channel), 1);
  rb_define_method(alsaRemoveEventsClass, "type=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_event_type), 1);
  rb_define_method(alsaRemoveEventsClass, "event_type=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_event_type), 1);
  rb_define_method(alsaRemoveEventsClass, "tag=", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events_set_tag), 1);


}