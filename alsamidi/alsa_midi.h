#if !defined(_RRTS_ALSA_MIDI_H)
#define _RRTS_ALSA_MIDI_H

/* $Id: alsa_midi.h,v 1.8 2010/02/23 22:56:55 ara Exp ara $ */

#include <ruby.h>
#pragma interface

#define WRAP_CONSTANT(s) rb_define_const(alsaDriver, #s, INT2NUM(s))
#define WRAP_STRING_CONSTANT(s) rb_define_const(alsaDriver, #s, rb_str_new2(s))

extern VALUE alsaDriver, alsaMidiError;

#define RAISE_MIDI_ERROR_FMT3(fmt, a, b, c) rb_raise(alsaMidiError, fmt, a, b, c)
#define RAISE_MIDI_ERROR_FMT2(fmt, a, b) rb_raise(alsaMidiError, fmt, a, b)
#define RAISE_MIDI_ERROR_FMT1(fmt, a) rb_raise(alsaMidiError, fmt, a)
#define RAISE_MIDI_ERROR(e) RAISE_MIDI_ERROR_FMT1("%s", snd_strerror(e))

static inline void rtts_deref(VALUE &v_val, const char *method)
{
//   fprintf(stderr, "%s:%d:rtts_deref(%p, %s)\n", __FILE__, __LINE__, &v_val, method);
  const ID id = rb_intern(method); // NEVER EVER static !!!!!!!!!!!!!!!!!!
//   fprintf(stderr, "rb_interned, id = %lu\n", id);
  if (rb_respond_to(v_val, id))
  {
//     fprintf(stderr, "responding, now calling!\n");
    v_val = rb_funcall(v_val, id, 0);
  }
//   fprintf(stderr, "ALIVE!\n");
}

static inline void rtts_deref_dirty(VALUE &v_val, const char *ivar)
{
  const ID id = rb_intern(ivar);
  if (RTEST(rb_ivar_defined(v_val, id)))
    v_val = rb_ivar_get(v_val, id);
}

// If ruby object v_val has method 'm' replace the whole thing with v_val.m
#define RRTS_DEREF(v_val, method) rtts_deref(v_val, #method)
/* If ruby object v_val has ivar 'varname' replace the whole thing with v_val.varname
Example: RRTS_DEREF_DIRTY(v_seq, @handle)

RRTS_DEREF_DIRTY is faster than RRTS_DEREF since we avoid the function call.
But it is slightly less flexible for the same reason
*/
#define RRTS_DEREF_DIRTY(v_val, varname) rtts_deref_dirty(v_val, #varname)


// If ruby object v_val has method 'm' replace the whole thing with v_val.m
#define RRTS_DEREF(v_val, method) rtts_deref(v_val, #method)

/* The following rules have been set

- This is a literal implementation of the almost full alsa snd_seq API

- functions have been made methods by using arg0 as self.

- obvious defaults are applied

- where values are often used as pairs (or even a c-struct) as in client+port=address
  I allow passing the address as a single entity

- methods starting with set, and with a single (required) argument have been
  replaced by the equivalent setter in ruby (as 'port=')

- set methods with 0 or 2 or more arguments still remain

- for methods starting with get_ this prefix has been removed

- getters that return a boolean are suffixed with '?'.

- errors became exceptions, in particular AlsaMidiError and ENOSPC somewhere

- ints that could be (or should be) interpreted as booleans have been replaced

- the wrapper classes in this library should be treated anonimously.

- methods with a return parameter in C have this method now return this parameter.

- methods that no longer return anything, or always nil now return self.

- in some cases, some parameters became meaningless.

- in some cases, alsa uses ambigues names. Example the macro snd_seq_ev_set_source only sets
  the port, and not the client. ev.source.port = p.
  This has been renamed to source_port, similarly source_client source, and the three setters are
  included.

IMPORTANT: using this API as is, will not be the most efficient way to deal with
alsa_midi.so.  Please use the ruby classes and additional methods in this library.
See alsa_midi++.cpp
This yields in particular for the MidiEvent API since the only way to write or read
a field is through a wrapped method. Even more, the C API has a lot of macros that
are now implemented as ruby methods. Again, this is not efficient.
However, it implies that existing programs can easily be ported, see for instance
rrecordmidi.rb which is a 1 on 1 port of arecordmidi.c

*/

#endif // _RRTS_ALSA_MIDI_H