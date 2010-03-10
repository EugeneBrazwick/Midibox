// $Id: alsa_midi_queue.h,v 1.2 2010/02/20 08:05:50 ara Exp $

#pragma interface

#include <ruby.h>

extern VALUE alsaQueueInfoClass, alsaQueueTempoClass, alsaQueueStatusClass;
extern void alsa_midi_queue_init();