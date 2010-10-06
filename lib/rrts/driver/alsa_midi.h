#if !defined(_RRTS_ALSA_MIDI_H)
#define _RRTS_ALSA_MIDI_H

#include <ruby.h>
#pragma interface

#define WRAP_CONSTANT(s) rb_define_const(alsaDriver, #s, INT2NUM(s))
#define WRAP_STRING_CONSTANT(s) rb_define_const(alsaDriver, #s, rb_str_new2(s))

extern VALUE alsaDriver, alsaMidiError;

#define RAISE_MIDI_ERROR_FMT6(fmt, a, b, c, d, e, f) rb_raise(alsaMidiError, fmt, a, b, c, d, e, f)
#define RAISE_MIDI_ERROR_FMT5(fmt, a, b, c, d, e) rb_raise(alsaMidiError, fmt, a, b, c, d, e)
#define RAISE_MIDI_ERROR_FMT4(fmt, a, b, c, d) rb_raise(alsaMidiError, fmt, a, b, c, d)
#define RAISE_MIDI_ERROR_FMT3(fmt, a, b, c) rb_raise(alsaMidiError, fmt, a, b, c)
#define RAISE_MIDI_ERROR_FMT2(fmt, a, b) rb_raise(alsaMidiError, fmt, a, b)
#define RAISE_MIDI_ERROR_FMT1(fmt, a) rb_raise(alsaMidiError, fmt, a)
#define RAISE_MIDI_ERROR_FMT0(fmt) rb_raise(alsaMidiError, fmt)
#define RAISE_MIDI_ERROR(when, e) \
  RAISE_MIDI_ERROR_FMT3("%s failed with error %d: %s", when, e, snd_strerror(e))

#define CantHappen() RAISE_MIDI_ERROR_FMT0("CantHappen")

/* helper, apply method to v_val, if the method exists. Replace v_val with the
result
*/
static inline void rrts_deref(VALUE &v_val, const char *method)
{
//   fprintf(stderr, "%s:%d:rrts_deref(%p, %s)\n", __FILE__, __LINE__, &v_val, method);
  const ID id = rb_intern(method); // NEVER EVER static !!!!!!!!!!!!!!!!!!
//   fprintf(stderr, "rb_interned, id = %lu\n", id);
  if (rb_respond_to(v_val, id))
  {
//     fprintf(stderr, "responding, now calling!\n");
    v_val = rb_funcall(v_val, id, 0);
  }
//   fprintf(stderr, "ALIVE!\n");
}

/* Same as rrts_deref but uses an instance variable and not a getter
*/
static inline void rrts_deref_dirty(VALUE &v_val, const char *ivar)
{
  const ID id = rb_intern(ivar);
  if (RTEST(rb_ivar_defined(v_val, id)))
    v_val = rb_ivar_get(v_val, id);
}

// If ruby object v_val has method 'm' replace the whole thing with v_val.m
#define RRTS_DEREF(v_val, method) rrts_deref(v_val, #method)
/* If ruby object v_val has ivar 'varname' replace the whole thing with v_val.varname
Example: RRTS_DEREF_DIRTY(v_seq, @handle)

RRTS_DEREF_DIRTY is faster than RRTS_DEREF since we avoid the function call.
But it is slightly less flexible for the same reason
*/
#define RRTS_DEREF_DIRTY(v_val, varname) rrts_deref_dirty(v_val, #varname)


// If ruby object v_val has method 'm' replace the whole thing with v_val.m
#define RRTS_DEREF(v_val, method) rrts_deref(v_val, #method)

/* This class behaves similar to VALUE except that the Garbage Collector will
automatically leave it alone.
*/
class GCSafeValue
{
private:
  VALUE V;
public:
  GCSafeValue(VALUE v): V(v) { rb_gc_register_address(&V); }
  ~GCSafeValue() { rb_gc_unregister_address(&V); }
  VALUE operator ->() const { return V; }
  VALUE operator *() const { return V; }
  operator VALUE() const { return V; }
  operator RData *() const { return RDATA(V); }
};

extern VALUE param2sym(uint param);

#if defined(TRACE)
#define trace(arg) fprintf(stderr, arg "\n");
#define trace1(arg, a) fprintf(stderr, arg "\n", a);
#define trace2(arg, a, b) fprintf(stderr, arg "\n", a, b);
#define trace3(arg, a, b, c) fprintf(stderr, arg "\n", a, b, c);
#define trace4(arg, a, b, c, d) fprintf(stderr, arg "\n", a, b, c, d);
#else
#define trace(arg)
#define trace1(arg, a)
#define trace2(arg, a, b)
#define trace3(arg, a, b, c)
#define trace4(arg, a, b, c, d)
#endif

#define INSPECT(x) RSTRING_PTR(rb_inspect(x))

#define rb_check_float_type(c) (rb_type(c) == T_FLOAT ? (c) : Qnil)

static inline void *rtts_calloc(size_t n)
{
  void * const result = xmalloc(n);
  memset(result, 0, n);
  return result;
}

#define XMALLOC(what) (what##_t *)rtts_calloc(what##_sizeof())

// strct could be 'queue_timer' for example. Excludes _t suffix.
// clss should then be QueueTimer
// The argcount for the wrapper should be -1 (== variable)
#define ALSA_MIDI_COPY_TO_TEMPLATE(strct, clss) \
static VALUE \
wrap_snd_seq_##strct##_copy_to(int argc, VALUE *argv, VALUE v_self) \
{ \
  VALUE v_dst; \
  rb_scan_args(argc, argv, "01", &v_dst); \
  VALUE retval = v_self; \
  snd_seq_##strct##_t *self, *dst; \
  if (NIL_P(v_dst)) \
  { \
    dst = XMALLOC(snd_seq_##strct); \
    v_dst = Data_Wrap_Struct(alsa##clss##Class, 0/*mark*/, snd_seq_##strct##_free/*free*/, dst); \
    retval = v_dst; \
  } \
  Data_Get_Struct(v_self, snd_seq_##strct##_t, self); \
  Data_Get_Struct(v_dst, snd_seq_##strct##_t, dst); \
  snd_seq_##strct##_copy(dst, self); \
  return retval; \
}

#define FETCH_ADDRESSES() \
VALUE v_clientid, v_portid; \
rb_scan_args(argc, argv, "11", &v_clientid, &v_portid); \
solve_address(v_clientid, v_portid)

/* portid can be unset, and both can be an instance of client or port resp.
*/
static inline void solve_address(VALUE &v_clientid, VALUE &v_portid)
{
  if (NIL_P(v_portid))
    {
      // Now it may be that clientid responds to 'address'
      RRTS_DEREF(v_clientid, address);
      v_clientid = rb_check_array_type(v_clientid);
      if (!RTEST(v_clientid)) RAISE_MIDI_ERROR_FMT0("API call error: address is not a tuple");
        // and we can continue...
      v_portid = rb_ary_entry(v_clientid, 1);
      v_clientid = rb_ary_entry(v_clientid, 0);
    }
  RRTS_DEREF(v_clientid, client);
  RRTS_DEREF(v_portid, port);
}


#endif // _RRTS_ALSA_MIDI_H