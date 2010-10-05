
#pragma implementation

#include "alsa_midi_timer.h"
#include "alsa_midi.h"

#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaQueueTimerClass;

/**  Document-method: RRTS::Driver::AlsaQueueTimer_i#copy_to
call-seq: copy_to([other = nil]) -> copy

Makes a copy of +self+. If +other+ is not specified it
returns a copy, otherwise it is used as targetbuffer.
*/
ALSA_MIDI_COPY_TO_TEMPLATE(queue_timer, QueueTimer)

/** call-seq: queue() -> queueid

Get the queue id
*/
static VALUE
wrap_snd_seq_queue_timer_get_queue(VALUE v_info)
{
  const snd_seq_queue_timer_t *info;
  Data_Get_Struct(v_info, const snd_seq_queue_timer_t, info);
  return INT2NUM(snd_seq_queue_timer_get_queue(info));
}

/** call-seq: type() ->  int

Get the timer type of a queue_timer container. 0 == alsa, 1 = realtime, 2 = ticks
See the constants +SND_SEQ_TIMER_+...
*/
static VALUE
wrap_snd_seq_queue_timer_get_type(VALUE v_info)
{
  const snd_seq_queue_timer_t *info;
  Data_Get_Struct(v_info, const snd_seq_queue_timer_t, info);
  return INT2NUM(snd_seq_queue_timer_get_type(info));
}

/** call-seq: id() -> int
const snd_timer_id_t *  snd_seq_queue_timer_get_id (const snd_seq_queue_timer_t *info)
Get the timer id of a queue_timer container.

*NOT* IMPLEMENTED YET

*/

/** call-seq: resolution() -> int

Get the timer resolution
*/
static VALUE
wrap_snd_seq_queue_timer_get_resolution(VALUE v_info)
{
  const snd_seq_queue_timer_t *info;
  Data_Get_Struct(v_info, const snd_seq_queue_timer_t, info);
  return UINT2NUM(snd_seq_queue_timer_get_resolution(info));
}

/** call-seq: type = int

Set the timer type of a queue_timer container. See RRTS::Driver::AlsaQueueTimer_i#type
*/
static VALUE
wrap_snd_seq_queue_timer_set_type(VALUE v_info, VALUE v_tp)
{
  snd_seq_queue_timer_t *info;
  Data_Get_Struct(v_info, snd_seq_queue_timer_t, info);
  snd_seq_queue_timer_set_type(info, (snd_seq_queue_timer_type_t)NUM2INT(v_tp));
  return Qnil;
}

/** call-seq: id = int

Set the timer id of a queue_timer container.

*NOT* IMPLEMENTED YET

*/

/** call-seq: resolution = int

Set the timer resolution
*/
static VALUE
wrap_snd_seq_queue_timer_set_resolution(VALUE v_info, VALUE v_reso)
{
  snd_seq_queue_timer_t *info;
  Data_Get_Struct(v_info, snd_seq_queue_timer_t, info);
  snd_seq_queue_timer_set_resolution(info, NUM2UINT(v_reso));
  return Qnil;
}

void
alsa_midi_timer_init()
{
  if (0)  // this is to make rdoc document it.
    {
      VALUE rrtsModule = rb_define_module("RRTS");
      alsaDriver = rb_define_module_under(rrtsModule, "Driver");
    }
  /** Document-class: RRTS::Driver::AlsaQueueTimer_i

  This class overlaps with other Alsa API, which is not associated with MIDI. Therefore not
  all methods are implemented, and I even don't know why these are.
  */
  alsaQueueTimerClass = rb_define_class_under(alsaDriver, "AlsaQueueTimer_i", rb_cObject);
  WRAP_CONSTANT(SND_SEQ_TIMER_ALSA); // = 0,
  WRAP_CONSTANT(SND_SEQ_TIMER_MIDI_CLOCK);
  WRAP_CONSTANT(SND_SEQ_TIMER_MIDI_TICK); // = 2
  WRAP_CONSTANT(SND_TIMER_GLOBAL_SYSTEM);//  0
  WRAP_CONSTANT(SND_TIMER_GLOBAL_RTC);//   1
  WRAP_CONSTANT(SND_TIMER_GLOBAL_HPET);//   2
//   WRAP_CONSTANT(SND_TIMER_GLOBAL_HRTIMER);//  3  DOES NOT EXIST
  WRAP_CONSTANT(SND_TIMER_OPEN_NONBLOCK);//  (1<<0)
  WRAP_CONSTANT(SND_TIMER_OPEN_TREAD);//   (1<<1)
  WRAP_CONSTANT(SND_TIMER_CLASS_NONE); // -1
  WRAP_CONSTANT(SND_TIMER_CLASS_SLAVE); // 0
  WRAP_CONSTANT(SND_TIMER_CLASS_GLOBAL);
  WRAP_CONSTANT(SND_TIMER_CLASS_CARD);
  WRAP_CONSTANT(SND_TIMER_CLASS_PCM);
  WRAP_CONSTANT(SND_TIMER_CLASS_LAST); // alias for the last one
  WRAP_CONSTANT(SND_TIMER_SCLASS_NONE);
  WRAP_CONSTANT(SND_TIMER_SCLASS_APPLICATION);
  WRAP_CONSTANT(SND_TIMER_SCLASS_SEQUENCER);
  WRAP_CONSTANT(SND_TIMER_SCLASS_OSS_SEQUENCER);
  WRAP_CONSTANT(SND_TIMER_EVENT_RESOLUTION);
  WRAP_CONSTANT(SND_TIMER_EVENT_TICK);
  WRAP_CONSTANT(SND_TIMER_EVENT_START);
  WRAP_CONSTANT(SND_TIMER_EVENT_STOP);
  WRAP_CONSTANT(SND_TIMER_EVENT_CONTINUE);
  WRAP_CONSTANT(SND_TIMER_EVENT_PAUSE);
  WRAP_CONSTANT(SND_TIMER_EVENT_EARLY);
  WRAP_CONSTANT(SND_TIMER_EVENT_SUSPEND);
  WRAP_CONSTANT(SND_TIMER_EVENT_RESUME);
  WRAP_CONSTANT(SND_TIMER_EVENT_MSTART);
  WRAP_CONSTANT(SND_TIMER_EVENT_MSTOP);
  WRAP_CONSTANT(SND_TIMER_EVENT_MPAUSE);
  WRAP_CONSTANT(SND_TIMER_EVENT_MSUSPEND);
  WRAP_CONSTANT(SND_TIMER_EVENT_MCONTINUE);
  WRAP_CONSTANT(SND_TIMER_EVENT_MRESUME);
  WRAP_CONSTANT(SND_TIMER_TYPE_HW);
  WRAP_CONSTANT(SND_TIMER_TYPE_SHM);
  WRAP_CONSTANT(SND_TIMER_TYPE_INET);
  rb_define_method(alsaQueueTimerClass, "copy_to", RUBY_METHOD_FUNC(wrap_snd_seq_queue_timer_copy_to), -1);
  rb_define_method(alsaQueueTimerClass, "type", RUBY_METHOD_FUNC(wrap_snd_seq_queue_timer_get_type), 0);
  rb_define_method(alsaQueueTimerClass, "type=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_timer_set_type), 1);
  rb_define_method(alsaQueueTimerClass, "queue", RUBY_METHOD_FUNC(wrap_snd_seq_queue_timer_get_queue), 0);
  rb_define_method(alsaQueueTimerClass, "resolution", RUBY_METHOD_FUNC(wrap_snd_seq_queue_timer_get_resolution), 0);
  rb_define_method(alsaQueueTimerClass, "resolution=", RUBY_METHOD_FUNC(wrap_snd_seq_queue_timer_set_resolution), 1);
}
