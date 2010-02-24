// $Id: alsa_midi_client.h,v 1.4 2010/02/20 20:52:50 ara Exp $

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
        // and we can continue...
      v_portid = rb_ary_entry(v_clientid, 1);
      v_clientid = rb_ary_entry(v_clientid, 0);
    }
  RRTS_DEREF(v_clientid, client);
  RRTS_DEREF(v_portid, port);
}

