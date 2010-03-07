
#include "alsa_midi.h"
#pragma interface

extern VALUE alsaClientInfoClass;
extern void alsa_midi_client_init();

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

#define FETCH_ADDRESSES() \
VALUE v_clientid, v_portid; \
rb_scan_args(argc, argv, "11", &v_clientid, &v_portid); \
solve_address(v_clientid, v_portid)

