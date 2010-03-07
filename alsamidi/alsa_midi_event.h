
#include <ruby.h>
#include <alsa/asoundlib.h>
#pragma interface

extern VALUE alsaMidiEventClass;
extern void alsa_midi_event_init();

// Important, the result must be freed using free
extern const char *dump_event(snd_seq_event_t *ev, const char *file = 0, int line = 0);

//  DOC on all events + types http://alsa-project.org/alsa-doc/alsa-lib/group___seq_events.html
