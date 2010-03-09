
// If changed do:         make
// To create Makefile:    ruby ./extruby.rb

// #define DUMP_API
#define DEBUG

#pragma implementation

#if defined(DUMP_API)
#define DUMP_STREAM stderr
#endif

#include "alsa_seq.h"
#include "alsa_midi.h"
#include "alsa_midi_event.h"
#include "alsa_midi_queue.h"
#include "alsa_midi_client.h"
#include "alsa_midi_port.h"
#include "alsa_client_pool.h"
#include "alsa_system_info.h"
#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaSequencerClass;
static VALUE alsaPollFdsClass;

/*
* 31.25 kbaud, one start bit, eight data bits, two stop bits.
* (The MIDI spec says one stop bit, but every transmitter uses two, just to be
* sure, so we better not exceed that to avoid overflowing the output buffer.)
*/
static size_t MIDI_BYTES_PER_SEC = 31250 / (1 + 8 + 2);

#if defined (DEBUG)
static bool AlsaSequencer_dump_notes = false;

/* dump_notes=(bool)
*/
static VALUE
AlsaSequencer_set_dump_notes(VALUE v_seq, VALUE v_on)
{
  AlsaSequencer_dump_notes = BOOL2INT(v_on);
  return Qnil;
}
#endif


/* int close

Close the sequencer.

Returns:
nil on success otherwise a negative error code

Closes the sequencer client and releases its resources. After a client is closed, an event with
SND_SEQ_EVENT_CLIENT_EXIT is broadcast to announce port.
The connection between other clients are disconnected.
Call this just before exiting your program.
*/
static VALUE
wrap_snd_seq_close(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_close(%p)\n", seq);
#endif
  const int r = snd_seq_close(seq);
  return r ? INT2NUM(r) : Qnil;
}

/* string name
get the name of the sequencer handle. This should really be 'default'.

Returns the ASCII identifier of the given sequencer handle. It's the same identifier
specified in Driver#seq_open

Do not confuse it with #client_name
*/
static VALUE
wrap_snd_seq_name(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  return rb_str_new2(snd_seq_name(seq));
}

/* int client_id
Returns the id of the specified client. If an error occurs, function raises AlsaMidiError
A client id is necessary to inquiry or to set the client information.
A user client is assigned from 128 to 191.
*/
static VALUE
wrap_snd_seq_client_id(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_client_id(%p)\n", seq);
#endif
  const int r = snd_seq_client_id(seq);
  if (r < 0) RAISE_MIDI_ERROR("fetching client_id", r);
  return INT2NUM(r);
}

/* nonblock([nonblock])
Set nonblock mode.

Parameters:
  [nonblock] false = block, true (the default) = nonblock mode

May raise AlsaMidiError

Change the blocking mode of the given client. In block mode, the client falls into
sleep when it fills the output memory
pool with full events. The client will be woken up after a certain amount of free
space becomes available.

The default mode on creation is +blocking+.
*/
static VALUE
wrap_snd_seq_nonblock(int argc, VALUE *v_params, VALUE v_seq)
{
  VALUE v_bool;
  rb_scan_args(argc, v_params, "01", &v_bool);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_nonblock(seq, NIL_P(v_bool) ? 1 : BOOL2INT(v_bool));
  if (r) RAISE_MIDI_ERROR("setting nonblocking mode", r);
  return Qnil;
}

/* client_name=(name)
set client name

This should update the connections as others see it.
*/
static VALUE
wrap_snd_seq_set_client_name(VALUE v_seq, VALUE v_name)
{
  snd_seq_t *      seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const char * const name = StringValueCStr(v_name);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_set_client_name(%p, %s)\n", seq, name);
#endif
  const int r = snd_seq_set_client_name(seq, name);
  if (r) RAISE_MIDI_ERROR("setting client_name", r);
  return v_seq;
}

/* AlsaMidiPort_i create_port(port_info)

create a sequencer port on the current client

Parameters:
  [port_info]    port construction information for the new port. Also returned.

Creates a sequencer port on the current client. The attributes of created port is
specified in info argument.

The client field in info argument is overwritten with the current client id.
The port id to be created can be specified via AlsaMidiPort_i#port_specified=.
You can get the created port id by reading the port pointer via AlsaMidiPort_i#port.

Each port has the capability bit-masks to specify the access capability of the port
from other clients.
The capability bit flags are defined as follows:

        * SND_SEQ_PORT_CAP_READ Readable from this port
        * SND_SEQ_PORT_CAP_WRITE Writable to this port.
        * SND_SEQ_PORT_CAP_SYNC_READ For synchronization (not implemented)
        * SND_SEQ_PORT_CAP_SYNC_WRITE For synchronization (not implemented)
        * SND_SEQ_PORT_CAP_DUPLEX Read/write duplex access is supported
        * SND_SEQ_PORT_CAP_SUBS_READ Read subscription is allowed
        * SND_SEQ_PORT_CAP_SUBS_WRITE Write subscription is allowed
        * SND_SEQ_PORT_CAP_NO_EXPORT Subscription management from 3rd client is disallowed

Each port has also the type bitmasks defined as follows:

        * SND_SEQ_PORT_TYPE_SPECIFIC Hardware specific port
        * SND_SEQ_PORT_TYPE_MIDI_GENERIC Generic MIDI device
        * SND_SEQ_PORT_TYPE_MIDI_GM General MIDI compatible device
        * SND_SEQ_PORT_TYPE_MIDI_GM2 General MIDI 2 compatible device
        * SND_SEQ_PORT_TYPE_MIDI_GS GS compatible device
        * SND_SEQ_PORT_TYPE_MIDI_XG XG compatible device
        * SND_SEQ_PORT_TYPE_MIDI_MT32 MT-32 compatible device
        * SND_SEQ_PORT_TYPE_HARDWARE Implemented in hardware
        * SND_SEQ_PORT_TYPE_SOFTWARE Implemented in software
        * SND_SEQ_PORT_TYPE_SYNTHESIZER Generates sound
        * SND_SEQ_PORT_TYPE_PORT Connects to other device(s)
        * SND_SEQ_PORT_TYPE_APPLICATION Application (sequencer/editor)

A port may contain specific midi channels, midi voices and synth voices.
These values could be zero as default.
*/
static VALUE
wrap_snd_seq_create_port(VALUE v_seq, VALUE v_portinfo)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_port_info_t *portinfo;
  Data_Get_Struct(v_portinfo, snd_seq_port_info_t, portinfo);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_create_port(%p, %p)\n", seq, portinfo);
#endif
  const int r = snd_seq_create_port(seq, portinfo);
  if (r < 0) RAISE_MIDI_ERROR("creating port", r);
  return v_portinfo;
}

/* int create_simple_port(name, capsbits, typebits)

create a port - simple version, buffering and queueing is not supported

Parameters:
  [name] the name of the port
  [caps] capability bits
  [type] type bits

Returns the created port number.
Creates a port with the given capability and type bits.
See #create_port.
*/
static VALUE
wrap_snd_seq_create_simple_port(VALUE v_seq, VALUE v_name, VALUE v_caps, VALUE v_type)
{
  snd_seq_t *      seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const char * const name = StringValueCStr(v_name);
  const unsigned caps = NUM2INT(v_caps);
  const unsigned type = NUM2INT(v_type);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_create_simple_port(%p, %s, %ud, %ud)\n", seq, name, caps, type);
#endif
  const int r = snd_seq_create_simple_port(seq, name, caps, type);
  if (r < 0) RAISE_MIDI_ERROR("creating simple port", r);
  return INT2NUM(r);
}

/* int delete_simple_port(port)
delete the port

Parameters:
  [port] portid or MidiPort

Returns nil on success or negative error code
*/
static VALUE
wrap_snd_seq_delete_simple_port(VALUE v_seq, VALUE v_portid)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  RRTS_DEREF_DIRTY(v_portid, @port);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_delete_simple_port(%p, %d)\n", seq, NUM2INT(v_portid));
#endif
  const int r = snd_seq_delete_simple_port(seq, NUM2INT(v_portid));
  return r ? INT2NUM(r) : Qnil;
}

/* int delete_port  port

delete a sequencer port on the current client

Parameters:
  [port]    portid or MidiPort to be deleted

Returns: nil on success, a negative errorcode otherwise
*/
static VALUE
wrap_snd_seq_delete_port(VALUE v_seq, VALUE v_portid)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  RRTS_DEREF_DIRTY(v_portid, @port);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_delete_port(%p, %d)\n", seq, NUM2INT(v_portid));
#endif
  const int r = snd_seq_delete_port(seq, NUM2INT(v_portid));
  return r ? INT2NUM(r) : Qnil; // C++ rule, do not raise exceptions on destructors
}

/* [AlsaMidiEvent_i, more] event_input
retrieve an event from sequencer

Obtains an input event from sequencer.
This function firstly receives the event byte-stream data from sequencer as much as
possible at once. Then it retrieves the first event record and store the pointer on ev.
By calling this function sequentially, events are extracted from the input buffer.
If there is no input from sequencer, function falls into sleep in blocking mode until
an event is received, or returns nil in non-blocking mode. Occasionally, it may raise
the ENOSPC SystemError. This means that the input FIFO of sequencer overran,
and some events are lost. Once this error is returned, the input FIFO is cleared automatically.

Function returns the event plus a boolean indicating more bytes remain in the input buffer.
It may also return nil in nonblocking mode.
An application can determine from the returned value whether to call input once more or not,
if there's more data it will probably(!) not block, even in blocking mode.

===== Multithreading
The caller should make note that ruby will block if a C-call blocks.  It would be wise
to create a separate thread for reading notes if blocking mode is active.
TODO: actually do this for Sequencer.  It is all still a bit experimental.
*/
static VALUE
wrap_snd_seq_event_input(VALUE v_seq)
{
  snd_seq_event_t *ev = 0;
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_event_input(%p, null)\n", seq);
#endif
  int r = snd_seq_event_input(seq, &ev);
  // according to mailing lists, these must NOT be freed.
  // And it can't even since event_free is deprecated
  if (r < 0)
    {
      VALUE cls = alsaMidiError;
      switch (r)
        {
        case -EAGAIN: return Qnil;
        case -ENOSPC:
          cls = rb_funcall(rb_mErrno, rb_intern("const_get"), 1, ID2SYM(rb_intern("ENOSPC")));
          r = -r;
          break;
        }
      rb_raise(cls, "%s", snd_strerror(r));
      ev = 0;
    }
//   fprintf(stderr, __FILE__":%d:event_input -> %p\n", __LINE__, ev);
  return rb_ary_new3(2, Data_Wrap_Struct(alsaMidiEventClass, 0/*mark*/, 0/*free*/, ev),
                     INT2BOOL(r > 0));
}

static void
DUMP_EVENT(snd_seq_event_t *ev, int line)
{
  // some types: NoTE == 5. NOTEON == 6 NOTEOFF = 7
  // CONTROLLER = 10, PGMCHANGE = 11
  // TEMPO = 35
  // SYSEX = 130
  const char *b = dump_event(ev, __FILE__, line);
  fprintf(stderr, "%s\n", b);
  free((void *)b);
}

typedef int (output_method)(snd_seq_t *, snd_seq_event_t *);
enum EOutput { Normal, Direct, Buffer, NrofMethods };

static const output_method *dispatch[NrofMethods] = {
  &snd_seq_event_output,
  &snd_seq_event_output_direct,
  &snd_seq_event_output_buffer
};

// returns remaining nr of events (>=0)
static inline VALUE do_event_output(snd_seq_t *seq, snd_seq_event_t *ev, VALUE v_func)
{
//   fprintf(stderr, "***do_event_output tp=%d, ch=%d, source.client=%d,flags=%d\n", ev->type, snd_seq_ev_is_note_type(ev) ? ev->data.note.channel : snd_seq_ev_is_control_type(ev) ? ev->data.control.channel : -1, ev->source.client, ev->flags);
#if defined(DEBUG)
  if (AlsaSequencer_dump_notes)
    {
      fprintf(stderr, "event_output(%s)\n", dump_event(ev));
      return INT2NUM(0);
    }
#endif
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_event_output*(%p, %p)\n", seq, ev);
#endif
  fprintf(stderr, "block when queue is full? %ld\n", time(0));
  const int r = (*dispatch[NUM2INT(v_func)])(seq, ev);
  fprintf(stderr, "-> %d, %ld\n", r, time(0));
  if (r < 0)
    {
      if (r == -EINVAL)
        {
          //HEURISTICS, probably this overflowed the queue.
          // NOTEON=6, NOTEOFF=7
          DUMP_EVENT(ev, __LINE__);
          RAISE_MIDI_ERROR_FMT1("sending event failed with alsa error %d, invalid data, but it "
                                "could well be an outputqueue-overflow", r);
        }
      RAISE_MIDI_ERROR("sending event", r);
    }
//DUMP_EVENT(ev, __LINE__); // Use ev.inspect
    //   fprintf(stderr, "Event sent, remaining in queue: %d, outbufsz=%ld\n", r, snd_seq_get_output_buffer_size(seq));
  return INT2NUM(r);
}

static inline void
WRITE_CHANNEL_IN_EVENT(snd_seq_event_t &ev, VALUE v_channel)
{
  if (snd_seq_ev_is_note_type(&ev))
    ev.data.note.channel = (NUM2INT(v_channel) - 1) & 0xf;
  else
    ev.data.control.channel = (NUM2INT(v_channel) - 1) & 0xf;
}

static VALUE  // callback for rb_iterate, val4 = seq+ev+retval+EOutput
send_callback(VALUE v_channel, VALUE v_val4)
{
//   fprintf(stderr, "%s:%d: in send_callback\n", __FILE__, __LINE__);
  // rb_check_type(v_val4, T_ARRAY); We control this
  VALUE v_seq = rb_ary_entry(v_val4, 0);
  VALUE v_ev = rb_ary_entry(v_val4, 1);
  VALUE v_outfunc  = rb_ary_entry(v_val4, 3);
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
//   fprintf(stderr, "%s:%d: in send_callback\n", __FILE__, __LINE__);
  WRITE_CHANNEL_IN_EVENT(*ev, v_channel);
  VALUE v_retval = do_event_output(seq, ev, NUM2INT(v_outfunc));
//   fprintf(stderr, "%s:%d: in send_callback\n", __FILE__, __LINE__);
  rb_ary_store(v_val4, 2, v_retval);
  return Qnil;
}

// v_ev is a MidiEvent!
static VALUE
do_event_output(bool ch_ref, snd_seq_t *seq, VALUE v_seq, VALUE v_ev, snd_seq_event_t &ev,
                VALUE v_func)
{
  if (ch_ref) // but no longer used. Bit of heuristics instead
    {
      VALUE v_channel = rb_iv_get(v_ev, "@channel"); // can be Enumerable! (or int in 1..16)
      if (rb_respond_to(v_channel, rb_intern("each")))
        {
//           fprintf(stderr, "@channel.respond_to?(:each)!!!\n");
          VALUE vev = Data_Wrap_Struct(alsaMidiEventClass, 0/*mark*/, 0/*free*/, &ev);
          VALUE retval = Qnil;
          VALUE val4 = rb_ary_new3(4, v_seq, vev, retval, v_func);
          // I hope this cast is valid?
//           fprintf(stderr, "callng rb_iterate on v_channel\n");
          rb_iterate(rb_each, v_channel, (VALUE (*)(...))send_callback, val4);
          // return r; This is the enum!! (so v_channel)
          return rb_ary_entry(val4, 2);
        }
      WRITE_CHANNEL_IN_EVENT(ev, v_channel);
    }
  VALUE r = do_event_output(seq, &ev, v_func);
//   fprintf(stderr, "did do_event_output\n");
  return r;
}

// return the LSB_ code if param is an MSB param
static inline uint
PARAM_IS_MSB_LSB_PAIR(uint param)
{
  if (param >= MIDI_CTL_MSB_BANK && param <= MIDI_CTL_MSB_GENERAL_PURPOSE4)
    return param + (MIDI_CTL_LSB_BANK - MIDI_CTL_MSB_BANK);
  switch (param)
    {
    case MIDI_CTL_NONREG_PARM_NUM_MSB: return MIDI_CTL_NONREG_PARM_NUM_LSB;
    case MIDI_CTL_REGIST_PARM_NUM_MSB: return MIDI_CTL_REGIST_PARM_NUM_LSB;
    }
  return 0;
}

static inline void
WRITE_TIME_IN_CHANNEL_i(VALUE v_time, snd_seq_event_t &ev, bool have_sender_queue)
{
//   fprintf(stderr, "WRITE_TIME_IN_CHANNEL_i, have_sender_queue=%d\n", have_sender_queue);
  if (!RTEST(v_time))
    {
      if (!have_sender_queue)
        {
          fprintf(stderr, __FILE__ ":%d: applying DIRECT\n", __LINE__);
          snd_seq_ev_set_direct(&ev);
        }
      return;
    }
  if (!have_sender_queue)
    RAISE_MIDI_ERROR_FMT0("attempt to set timestamps, but no MidiQueue supplied");
  // if (ev.flags & SND_SEQ_TIME_STAMP_TICK)  flags is 0!!!!!
  if (!(ev.flags & SND_SEQ_TIME_STAMP_REAL))
    {
//       fprintf(stderr, "using time\n");
      ev.time.tick = NUM2UINT(v_time);
    }
  else
    {
//       fprintf(stderr, "splittin time in sec + nsec\n");
      VALUE v_time = rb_check_array_type(v_time);
      if (!RTEST(v_time))
        RAISE_MIDI_ERROR_FMT1("flags = %x -> SND_SEQ_TIME_STAMP_REAL, but no array", ev.flags);
      ev.time.time.tv_sec = NUM2UINT(rb_ary_entry(v_time, 0));
      ev.time.time.tv_nsec = NUM2UINT(rb_ary_entry(v_time, 1));
    }
}

// depending on ev.flags we use tick or tv_sec/tv_nsec tuple (array)
#define WRITE_TIME_IN_CHANNEL(t, e) WRITE_TIME_IN_CHANNEL_i(t, e, have_sender_queue)

static uint decode_a_note(const char *pat)
{
  int base; // 0..11  where C == 0 , C#==Db == 1 upto B=11
  //int oct; // 0..9. 12*oct+base is the midi notenr. Max 12*9+11 = 119
   // Chances are keyboards will refuse to play anything outside C1..C8 though

  switch (*pat)
    {
    case 'C': case 'c': base = 0; break;
    case 'D': case 'd': base = 2; break;
    case 'E': case 'e': base = 4; break;
    case 'F': case 'f': base = 5; break;
    case 'G': case 'g': base = 7; break;
    case 'A': case 'a': base = 9; break;
    case 'B': case 'b': base = 11; break;
    default: RAISE_MIDI_ERROR_FMT1("illegal note pattern '%s'", pat);
    }
  int i = 1;
  if (pat[1] == '#')
    {
      if (base == 11)
        RAISE_MIDI_ERROR_FMT1("illegal note pattern '%s'", pat);
      base++, i++;
    }
  else if (pat[1] == 'b')
  {
    if (base == 0)
      RAISE_MIDI_ERROR_FMT1("illegal note pattern '%s'", pat);
    base--, i++;
  }
  if (pat[i] < '0' || pat[i] > '9')
    RAISE_MIDI_ERROR_FMT1("illegal note pattern '%s'", pat);
  return (pat[i] - '0') * 12 + base;
}

static VALUE
wrap_snd_seq_event_output_func(VALUE v_seq, VALUE v_ev, EOutput func)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  VALUE v_func = INT2NUM(func);
  // Now it's gonna be hairy. v_ev might be a MidiEvent descendant and not 'Data'.
  const ID id_MidiEvent = rb_intern("MidiEvent");
  if (rb_const_defined(rb_mKernel, id_MidiEvent))
    {
      VALUE v_MidiEvent = rb_const_get(rb_mKernel, id_MidiEvent);
    //   VALUE v_is_a_MidiEvent = rb_funcall(v_ev, ID2SYM(rb_intern("kind_of?")), 1, v_MidiEvent);
      if (RTEST(rb_obj_is_kind_of(v_ev, v_MidiEvent)))
        {
    //       fprintf(stderr, "MIDIEVENT\n");
          snd_seq_event_t ev;  // I follow the code from aplymidi.c
          snd_seq_ev_clear(&ev);
          /* v_ev has the following properties (recap), which may all be nil as well.
            type: a symbol and never nil
            flags: a hash with bool values! and never nil either
            param: a symbol or integer
            value: note or queueparam etc. sometimes 14 bits or maybe even 21 so may issue 2 or 3 events!
            specifics:
                - channel 4 bit
                - duration 7 bit
                - source, dest  MidiPort
                - sender_queue MidiQueue
                - tick, either tick or realtime-tuple [sec, nsec]
          */
          const ID id_sender_queue = rb_intern("@sender_queue");
          bool have_sender_queue = false; // used later on through macro!!!
          VALUE v_sender_queue;
          if (rb_ivar_defined(v_ev, id_sender_queue))
            {
              v_sender_queue = rb_ivar_get(v_ev, id_sender_queue);
              // IMPORTANT @queue is the queue for queue notifications, which may differ
              RRTS_DEREF_DIRTY(v_sender_queue, @id);
              have_sender_queue = RTEST(v_sender_queue);
              if (have_sender_queue)
                ev.queue = NUM2INT(v_sender_queue);
            }
          else
            snd_seq_ev_set_direct(&ev); // !
    //       fprintf(stderr, "get source\n");
          VALUE v_sourceport = rb_iv_get(v_ev, "@source");
          const ID id_iv_port = rb_intern("@port");
          const ID id_iv_client_id = rb_intern("@client_id");
    //       fprintf(stderr, "test v_sourceport\n");
          if (RTEST(v_sourceport))  // TODO: can you actually leave this out?? Should be an error?
            {
              ev.source.port = NUM2INT(rb_ivar_get(v_sourceport, id_iv_port));
              ev.source.client = NUM2INT(rb_ivar_get(v_sourceport, id_iv_client_id));
            }
    //       fprintf(stderr, "callback debunktypeflags_i\n");
          VALUE v_typeflags = rb_funcall(v_ev, rb_intern("debunktypeflags_i"), 0);
    //       fprintf(stderr, "split result\n");
          v_typeflags = rb_check_array_type(v_typeflags);
          if (!RTEST(v_typeflags)) RAISE_MIDI_ERROR_FMT0("BUG: bad type returned from debunktypeflags_i");
          ev.type = NUM2INT(rb_ary_entry(v_typeflags, 0));
          ev.flags = NUM2INT(rb_ary_entry(v_typeflags, 1)); // from event.flags SND_SEQ_TIME_STAMP_TICK | SND_SEQ_TIME_STAMP_ABS;
    //       fprintf(stderr, "time\n");
          VALUE v_time = rb_iv_get(v_ev, "@time");
          unsigned char *ch_ref = 0; // We only use that it is 0 or not !!!!
          WRITE_TIME_IN_CHANNEL(v_time, ev);
    //       fprintf(stderr, "dest\n");
          VALUE v_destport = rb_iv_get(v_ev, "@dest");

          /* This is probably incorrect. But aplaymidi uses explicit senders iso a connection
          so it may not be a good example
          */
          if (!RTEST(v_destport))
            RAISE_MIDI_ERROR_FMT0("no destination set in event");
          ev.dest.port = NUM2INT(rb_ivar_get(v_destport, id_iv_port));
          ev.dest.client = NUM2INT(rb_ivar_get(v_destport, id_iv_client_id));
    //       fprintf(stderr, "typeswitch\n");
          switch (ev.type)
            {
            case SND_SEQ_EVENT_NOTE:
              {
                ev.data.note.duration = NUM2UINT(rb_iv_get(v_ev, "@duration"));
                VALUE v_off_vel = rb_iv_get(v_ev, "@off_velocity");
                ev.data.note.off_velocity = RTEST(v_off_vel) ? NUM2UINT(v_off_vel) : 0;
                // fall through !
              }
            case SND_SEQ_EVENT_NOTEON:
            case SND_SEQ_EVENT_NOTEOFF:
            case SND_SEQ_EVENT_KEYPRESS: // == aftertouch
              {
    // fprintf(stderr, "type=%d,NOTEON/OFF/KEYPRES\n", ev.type);
                snd_seq_ev_set_fixed(&ev);
                ch_ref = &ev.data.note.channel;
                VALUE v_note = rb_iv_get(v_ev, "@value");
                if (FIXNUM_P(v_note))
                  ev.data.note.note = NUM2UINT(v_note);
                else
                  ev.data.note.note = decode_a_note(StringValueCStr(v_note));
                VALUE v_vel = rb_iv_get(v_ev, "@velocity");
                ev.data.note.velocity = RTEST(v_vel) ? NUM2UINT(v_vel) : 0;
                break;
              }
            case SND_SEQ_EVENT_CONTROLLER:
              {
                snd_seq_ev_set_fixed(&ev);
                ch_ref = &ev.data.control.channel;
                VALUE v_param_coarse = rb_check_array_type(rb_funcall(v_ev, rb_intern("debunkparam_i"), 0));
                if (!RTEST(v_param_coarse)) RAISE_MIDI_ERROR_FMT0("BUG: bad type returned by debunkparam_i");
//                 fprintf(stderr, "%s:% : debunking done\n", __FILE__, __LINE__);
                const bool coarse = RTEST(rb_ary_entry(v_param_coarse, 1));
                const uint param = ev.data.control.param = NUM2INT(rb_ary_entry(v_param_coarse, 0));
//                 fprintf(stderr, "got param\n");
                VALUE v_value = rb_iv_get(v_ev, "@value");
                int value;
                uint lsb_version = PARAM_IS_MSB_LSB_PAIR(param);
                if (lsb_version)
                  {
                    int msb, lsb = 0;
//                     fprintf(stderr, "%d: coarse=%d, value=%d,param=%u\n", __LINE__, coarse, value,ev.data.control.param);
                    if (coarse)
                      msb = NUM2INT(v_value);
                    else if FIXNUM_P(v_value)
                      {
                        const int v = NUM2INT(v_value);
                        msb = v << 7;
                        lsb = v & 0x7f;
                      }
                    else
                      {
                        VALUE v_ar = rb_check_array_type(v_value);
                        if (NIL_P(v_ar)) msb = 0;
                        else
                          {
                            VALUE v0 = rb_ary_entry(v_ar, 0), v1 = rb_ary_entry(v_ar, 1);
                            if (!RTEST(v0)) RAISE_MIDI_ERROR_FMT1("Bad args for param %d", param);
                            msb = NUM2INT(v0);
                            lsb = RTEST(v1) ? NUM2INT(v1) : 0;
                          }
                      }
                    ev.data.control.value = msb;
                    do_event_output(ch_ref, seq, v_seq, v_ev, ev, v_func);
//             fprintf(stderr, "%s:%d: CONTROLLER(param=%u,value=%d)\n", __FILE__,__LINE__, lsb_version, lsb);
                    ev.data.control.param = lsb_version;
                    value = lsb;
                  }
                else
                    value = NUM2INT(v_value) & 0x7f;
                ev.data.control.value = value;
    // fprintf(stderr, "%s:%d: CONTROLLER(param=%u,value=%d)\n", __FILE__,__LINE__, param, value & 0x7f);
                break;
              }
            case SND_SEQ_EVENT_PGMCHANGE:
              {
                snd_seq_ev_set_fixed(&ev);
                ch_ref = &ev.data.control.channel;
                VALUE v_value = rb_iv_get(v_ev, "@value");
                int value = 0;
                if (FIXNUM_P(v_value))
                    value = NUM2INT(v_value);
                else
                  {
                    VALUE v_ar = rb_check_array_type(v_value);
                    if (!NIL_P(v_ar))
                      {
                        const int len = NUM2INT(rb_funcall(v_ar, rb_intern("length"), 0));
                        const int msb = NUM2INT(rb_ary_entry(v_ar, 0));
                        const int lsb = len == 2 ? 0 : NUM2INT(rb_ary_entry(v_ar, 1));
                        value = NUM2INT(rb_ary_entry(v_ar, len == 2 ? 1 : 2));
                        snd_seq_event_t ev_bank = ev;
                        ev_bank.type = SND_SEQ_EVENT_CONTROLLER;
                        ev_bank.data.control.param = MIDI_CTL_MSB_BANK;
                        ev_bank.data.control.value = msb;
                        do_event_output(ch_ref, seq, v_seq, v_ev, ev_bank, v_func);
                        ev_bank.data.control.param = MIDI_CTL_LSB_BANK;
                        ev_bank.data.control.value = lsb;
                        do_event_output(ch_ref, seq, v_seq, v_ev, ev_bank, v_func);
                      }
                  }
                ev.data.control.value = value;
                break;
              }
            case SND_SEQ_EVENT_CHANPRESS:
            case SND_SEQ_EVENT_PITCHBEND:
              {
                snd_seq_ev_set_fixed(&ev);
                ch_ref = &ev.data.control.channel;
                const int value = NUM2INT(rb_iv_get(v_ev, "@value"));
                ev.data.control.value = value;
                break;
              }
            case SND_SEQ_EVENT_SYSEX:
              {
                // value is a string.
                VALUE v_val = rb_iv_get(v_ev, "@value");
                rb_check_type(v_val, T_STRING);
                size_t length = RSTRING_LEN(v_val);
                snd_seq_ev_set_variable(&ev, length, RSTRING_PTR(v_val));
                if (length > MIDI_BYTES_PER_SEC)
                  ev.data.ext.len = MIDI_BYTES_PER_SEC; // ??
                size_t event_size = snd_seq_event_length(&ev); // used to crash ?
                if (event_size + 1 > snd_seq_get_output_buffer_size(seq))
                  {
                    int err = snd_seq_drain_output(seq);
                    if (err < 0) RAISE_MIDI_ERROR("draining output", err);
                    err = snd_seq_set_output_buffer_size(seq, event_size + 1);
                    if (err < 0) RAISE_MIDI_ERROR("growing output buffer", err);
                  }
                while (length > MIDI_BYTES_PER_SEC)
                  {
                    int err = snd_seq_event_output(seq, &ev);
                    if (err < 0) RAISE_MIDI_ERROR("sending sysex", err);
                    err = snd_seq_drain_output(seq);
                    if (err < 0) RAISE_MIDI_ERROR("draining output", err);
                    err = snd_seq_sync_output_queue(seq);
                    if (err < 0) RAISE_MIDI_ERROR("syncing queue", err);
                    // sleep(1) ; // AARGH ?
                    *(char **)ev.data.ext.ptr += MIDI_BYTES_PER_SEC;
                    length -= MIDI_BYTES_PER_SEC; // > 0
                  }
                ev.data.ext.len = length; // > 0
                // end send the remainder as well.
                break;
              }
            case SND_SEQ_EVENT_TEMPO:
              {
                snd_seq_ev_set_fixed(&ev);
                const int queue = NUM2INT(rb_iv_get(v_ev, "@queue"));
                const uint tempo = NUM2UINT(rb_iv_get(v_ev, "@value"));
                ev.dest.client = SND_SEQ_CLIENT_SYSTEM;
                ev.dest.port = SND_SEQ_PORT_SYSTEM_TIMER;
                ev.data.queue.queue = queue;
                ev.data.queue.param.value = tempo;
                break;
              }
            case SND_SEQ_EVENT_RESET:
            case SND_SEQ_EVENT_TUNE_REQUEST:
            case SND_SEQ_EVENT_SENSING:
            case SND_SEQ_EVENT_ECHO:
            case SND_SEQ_EVENT_NONE:
            case SND_SEQ_EVENT_STOP:
            case SND_SEQ_EVENT_START:
            case SND_SEQ_EVENT_CONTINUE:
              snd_seq_ev_set_fixed(&ev);
              break;
            default:
              RAISE_MIDI_ERROR_FMT1("invalid/unsupported type %d", ev.type);
              break;
            }
          return do_event_output(ch_ref, seq, v_seq, v_ev, ev, v_func);
        }
    }
  snd_seq_event_t *ev;
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
  return do_event_output(seq, ev, v_func);
}

/* int event_output(event)

output an event

Parameters:
[event] AlsaMidiEvent_i or MidiEvent to be output

Returns the number of remaining events.

An event is once expanded on the output buffer. The output buffer will be
drained (flushed) automatically if it becomes full.  However, this may still block the
process (and ruby) if the other side does not read fast enough. For this problem, see
also #event_input.

If events remain unprocessed on the output buffer before drained, the size of total
byte data on output buffer is returned. If the output buffer is empty, this returns zero.

You can assume that the event can be freed after calling this method, even if it contains
dynamic data (sysex/variable).
*/
static VALUE
wrap_snd_seq_event_output(VALUE v_seq, VALUE v_ev)
{
  return wrap_snd_seq_event_output_func(v_seq, v_ev, Normal);
}

/* int event_output_buffer(event)
See #event_output. The same, but the buffer is not flushed when becoming full.
*/
static VALUE
wrap_snd_seq_event_output_buffer(VALUE v_seq, VALUE v_ev)
{
  return wrap_snd_seq_event_output_func(v_seq, v_ev, Buffer);
}

/* int event_output_direct(event)
See #event_output. The same, except no buffer is used and timestamping is impossible.
*/
static VALUE
wrap_snd_seq_event_output_direct(VALUE v_seq, VALUE v_ev)
{
  return wrap_snd_seq_event_output_func(v_seq, v_ev, Direct);
}

/* bool query_next_client(clientinfo)
Parameters:
  [clientinfo] query pattern and result

Queries the next client. The search begins at the client with an id one greater
than client field in info.
If a client is found, its attributes are stored in info, and true is returned.
If not found (-ENOENT I hope) false is returned.
Otherwise an AlsaMidiError is raised

In this case -ENOENT seems to indicate endofdata.  However, the specification doesn't say this.
*/
static VALUE
wrap_snd_seq_query_next_client(VALUE v_seq, VALUE v_client_info)
{
  snd_seq_t *seq;
  snd_seq_client_info_t *client_info;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  Data_Get_Struct(v_client_info, snd_seq_client_info_t, client_info);
  const int r = snd_seq_query_next_client(seq, client_info);
//   fprintf(stderr, "snd_seq_query_next_client -> %d\n", r);
  if (r == -ENOENT) return Qfalse;
  if (r < 0) rb_raise(alsaMidiError, "%s", snd_strerror(r));
  return Qtrue;
}

/* bool query_next_port(portinfo)
Parameters:
  [portinfo]  query pattern and result

Queries the next matching port on the client specified in info argument. The search
begins at the next port specified in port field of info argument.
For finding the first port at a certain client, give -1.
If a matching port is found, its attributes are stored on info and function returns true
and false otherwise.
*/
static VALUE
wrap_snd_seq_query_next_port(VALUE v_seq, VALUE v_port_info)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_port_info_t *port_info;
  Data_Get_Struct(v_port_info, snd_seq_port_info_t, port_info);
  const int r = snd_seq_query_next_port(seq, port_info);
  if (r == -ENOENT) return Qfalse;
  if (r < 0) RAISE_MIDI_ERROR("iterating ports", r);
  return Qtrue;
}

/* int alloc_named_queue(name)

allocate a queue with the specified name.
According to aplaymidi.c this queue is locked (which is just fine)

Parameters:
   [name] the name of the new queue

Returns the queue id (zero or positive) on success, throws AlsaMidiError otherwise
*/
static VALUE
wrap_snd_seq_alloc_named_queue(VALUE v_seq, VALUE v_name)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_alloc_named_queue(seq, RSTRING_PTR(v_name));
  if (r < 0) RAISE_MIDI_ERROR("allocating named queue", r);
  return INT2NUM(r);
}

/* subinfo subscribe_port(subinfo)
Parameters:
  [subinfo] subscription information

Subscribes a connection between two ports. The subscription information is stored in
the subinfo argument (returned as well)
*/
static VALUE
wrap_snd_seq_subscribe_port(VALUE v_seq, VALUE v_port_subs)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_subscribe_port(%p, %p)\n", seq, port_subs);
#endif
  const int r = snd_seq_subscribe_port(seq, port_subs);
  if (r < 0) RAISE_MIDI_ERROR("port subscription", r);
  return v_port_subs;
}

/* int unsubscribe_port(port_sub)
Returns nil if OK, otherwise negative errorcode. Reverse of subscribing.
*/
static VALUE
wrap_snd_seq_unsubscribe_port(VALUE v_seq, VALUE v_port_subs)
{
  snd_seq_port_subscribe_t *port_subs;
  Data_Get_Struct(v_port_subs, snd_seq_port_subscribe_t, port_subs);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_unsubscribe_port(%p, %p)\n", seq, port_subs);
#endif
  const int r = snd_seq_unsubscribe_port(seq, port_subs);
  return r ? INT2NUM(r) : Qnil;
}

#define FETCH_CONNECTION_ADDRESSES(prefix) \
VALUE v_myportid, v_##prefix##_clientid, v_##prefix##_portid; \
rb_scan_args(argc, v_params, "21", &v_myportid, &v_##prefix##_clientid, &v_##prefix##_portid); \
solve_address(v_##prefix##_clientid, v_##prefix##_portid); \
RRTS_DEREF_DIRTY(v_myportid, @port)

/* self connect_to(myport, dest_address)
simple subscription (w/o exclusive & time conversion)

Parameters:
  [myport]       the portid or MidiPort as sender
  [dest_address] a tuple, or two single arguments as client + port, or a MidiPort

Connect from the given receiver port in the current client to the given destination client:port.
*/
static VALUE
wrap_snd_seq_connect_to(int argc, VALUE *v_params, VALUE v_seq)
{
  FETCH_CONNECTION_ADDRESSES(dest);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int dest_cid = NUM2INT(v_dest_clientid), dest_pid = NUM2INT(v_dest_portid);
  const int r = snd_seq_connect_to(seq, NUM2INT(v_myportid), dest_cid, dest_pid);
  if (r) RAISE_MIDI_ERROR_FMT3("cannot connect to port %d:%d - %s", dest_cid, dest_pid, snd_strerror(r));
  return v_seq;
}

/* connect_from(myport, source_address)
Connect from the given sender client:port to the given destination port in the current client.
See #connect_to
*/
static VALUE
wrap_snd_seq_connect_from(int argc, VALUE *v_params, VALUE v_seq)
{
  //   fprintf(stderr, "connect_from(argc=%d)\n", argc);
  FETCH_CONNECTION_ADDRESSES(src);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int src_cid = NUM2INT(v_src_clientid), src_pid = NUM2INT(v_src_portid);
  const int r = snd_seq_connect_from(seq, NUM2INT(v_myportid), src_cid, src_pid);
  if (r) RAISE_MIDI_ERROR_FMT3("cannot connect from port %d:%d - %s", src_cid, src_pid, snd_strerror(r));
  return v_seq;
}

/* int disconnect_from(myport, source_address)
See #connect_to
Returns nil if OK, otherwise negative errorcode
*/
static VALUE
wrap_snd_seq_disconnect_from(int argc, VALUE *v_params, VALUE v_seq)
{
  FETCH_CONNECTION_ADDRESSES(src);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_disconnect_from(seq, NUM2INT(v_myportid), NUM2INT(v_src_clientid), NUM2INT(v_src_portid));
  return r ? INT2NUM(r) : Qnil;
}

/* int disconnect_to(myport, dest_address)
See also #disconnect_from
*/
static VALUE
wrap_snd_seq_disconnect_to(int argc, VALUE *v_params, VALUE v_seq)
{
  FETCH_CONNECTION_ADDRESSES(dest);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_disconnect_to(seq, NUM2INT(v_myportid), NUM2INT(v_dest_clientid), NUM2INT(v_dest_portid));
  return r ? INT2NUM(r) : Qnil;
}

/* [clientid, portid] parse_address(arg)
parse the given string and get the sequencer address

Parameters:
  [arg] the string to be parsed

Returns clientid + portid on success or it raises a AlsaMidiError.

This function parses the sequencer client and port numbers from the given string.
The client and port tokes are separated by either colon or period, e.g. 128:1.
The function accepts also a client name not only digit numbers.

The arguments could be '20:2' or 'MIDI2:0' etc.  Portnames are not understood!

See Driver#parse_address
*/
static VALUE
wrap_snd_seq_parse_address(VALUE v_seq, VALUE v_arg)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_addr_t ret;
  const char *const arg = StringValuePtr(v_arg);
  const int r = snd_seq_parse_address(seq, &ret, arg);
  if (r < 0) RAISE_MIDI_ERROR_FMT2("Invalid port '%s' - %s", arg, snd_strerror(r));
  return rb_ary_new3(2, INT2NUM(ret.client), INT2NUM(ret.port));
}

/* self sync_output_queue
wait until all events are processed
This function waits (blocks) until all events of this client are processed.
See the note on blocking ruby at #event_output
*/
static VALUE
wrap_snd_seq_sync_output_queue(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_sync_output_queue(seq);
  // According to the CRAPPY docs this should return 0 or negative errorcode.
  // However it apparently can also return 1. I hope it's OK.
  if (r < 0) RAISE_MIDI_ERROR("syncing output queue", r);
  return v_seq;
}

/* int drain_output
drain output buffer to sequencer
Returns 0 when all events are drained and sent to sequencer. When events
still remain on the buffer, the byte size of remaining events are returned.
On error a AlsaMidiError is raised.
This function drains all pending events on the output buffer.
The function returns immediately after the events are sent to the queues regardless
whether the events are processed or not. To get synchronization with the
all event processes, use sync_output_queue after calling this function.
*/
static VALUE
wrap_snd_seq_drain_output(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_drain_output(seq);
  if (r < 0) RAISE_MIDI_ERROR("draining output", r);
  return INT2NUM(r);
}

/* int input_pending(fetch_sequencer_fifo = true)

 check events in input buffer

 Returns the byte size of remaining input events on input buffer.

 If events remain on the input buffer of user-space, function returns the
 total byte size of events on it.
 If fetch_sequencer_fifo argument is true, this function checks the presence of
 events on sequencer FIFO.
 When events exist, they are transferred to the input buffer, and the number of
 received events are returned.
 If fetch_sequencer argument is zero and no events remain on the input buffer,
 the function simply returns zero.
*/
static VALUE
wrap_snd_seq_event_input_pending(int argc, VALUE *v_params, VALUE v_seq)
{
  VALUE v_fetchseq;
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  rb_scan_args(argc, v_params, "01", &v_fetchseq);
  return INT2NUM(snd_seq_event_input_pending(seq, NIL_P(v_fetchseq) ? 1 : NUM2INT(v_fetchseq)));
}

/* self drop_input
clear the input buffer and and remove all events in the sequencer queue
*/
static VALUE
wrap_snd_seq_drop_input(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_drop_input(seq);
  return v_seq;
}

/* self drop_input_buffer

remove all events on user-space input FIFO
*/
static VALUE
wrap_snd_seq_drop_input_buffer(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_drop_input_buffer(seq);
  return v_seq;
}

/* self set_queue_info(queue, info)

change the queue attributes

Parameters:
  queue   queueid or MidiQueue to change
  info    information changed
*/
static VALUE
wrap_snd_seq_set_queue_info(VALUE v_seq, VALUE v_qid, VALUE v_qi)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  RRTS_DEREF_DIRTY(v_qid, @id);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_set_queue_info(%p, %d, %p)\n", seq, NUM2INT(v_qid), qi);
#endif
  const int r = snd_seq_set_queue_info(seq, NUM2INT(v_qid), qi);
  if (r) RAISE_MIDI_ERROR("setting queue info", r);
  return v_seq;
}

/* self set_queue_tempo(queue, tempo)

set the tempo of the queue

Parameters:
  [queue] queueid or MidiQueue to change the tempo
  [tempo] AlsaQueueTempo_i or Tempo instance
*/
static VALUE
wrap_snd_seq_set_queue_tempo(VALUE v_seq, VALUE v_qid, VALUE v_tempo)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  RRTS_DEREF_DIRTY(v_tempo, @handle);
  RRTS_DEREF_DIRTY(v_qid, @id);
  snd_seq_queue_tempo_t *tempo;
  Data_Get_Struct(v_tempo, snd_seq_queue_tempo_t, tempo);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_set_queue_tempo(%p, %d, %p)\n", seq, NUM2INT(v_qid), tempo);
#endif
  const int r = snd_seq_set_queue_tempo(seq, NUM2INT(v_qid), tempo);
  if (r < 0)
    RAISE_MIDI_ERROR_FMT3("Cannot set queue tempo (%u/%i): %s",
                          snd_seq_queue_tempo_get_tempo(tempo), snd_seq_queue_tempo_get_ppq(tempo), snd_strerror(r));
  return v_seq;
}

/* AlsaQueueInfo_i queue_info q [, info]

obtain queue attributes

Parameters:
  [q]     queueid or MidiQueue to query
  [info] room for information returned, if omitted it is allocated

Returns info
*/
static VALUE
wrap_snd_seq_get_queue_info(int argc, VALUE *v_params, VALUE v_seq)
{
  VALUE v_qid, v_qi;
  rb_scan_args(argc, v_params, "11", &v_qid, &v_qi);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_queue_info_t *qi;
  if (NIL_P(v_qi))
    {
      const int r = snd_seq_queue_info_malloc(&qi);
      if (r < 0) RAISE_MIDI_ERROR("allocating queue info", r);
      v_qi = Data_Wrap_Struct(alsaQueueInfoClass, 0/*mark*/, snd_seq_queue_info_free/*free*/, qi);
    }
  else
      Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  RRTS_DEREF_DIRTY(v_qid, @id);
  const int r = snd_seq_get_queue_info(seq, NUM2INT(v_qid), qi);
  if (r < 0) RAISE_MIDI_ERROR("retrieving queue info", r);
  return v_qi;
}

/* self remove_events([remove_event_descriptor])

remove events on input/output buffers and pools

Parameters:
  [remove_events_descriptor] remove event container.
                             If omitted all output events except OFFS are erased.

Removes matching events with the given condition from input/output buffers and pools.
This can be used to erase events that are currently underway, parked in qeueus etc.
Use it to cleanly exit a process
*/
static VALUE
wrap_snd_seq_remove_events(int argc, VALUE *argv, VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  VALUE v_rmp;
  rb_scan_args(argc, argv, "01", &v_rmp);
  snd_seq_remove_events_t *m;
  const bool allocated = NIL_P(v_rmp);
  if (allocated)
    {
      const int r = snd_seq_remove_events_malloc(&m);
      if (r < 0) RAISE_MIDI_ERROR("allocating remove_events", r);
      snd_seq_remove_events_set_condition(m, SND_SEQ_REMOVE_IGNORE_OFF | SND_SEQ_REMOVE_OUTPUT);
    }
  else
      Data_Get_Struct(v_rmp, snd_seq_remove_events_t, m);
  snd_seq_remove_events(seq, m);
  if (allocated)
    free(m);
  return v_seq;
}

/* int create_queue(queueinfo)

create a queue

Parameters:
   [queueinfo]  AlsaQueueInfo_i instance used to initialize

Returns the queue id (zero or positive) on success or raise AlsaMidiError.
The queue should be freed using #free_queue.
*/
static VALUE
wrap_snd_seq_create_queue(VALUE v_seq, VALUE v_qi)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_create_queue(%p, %p)\n", seq, qi);
#endif
  const int r = snd_seq_create_queue(seq, qi);
  if (r < 0) RAISE_MIDI_ERROR("creating queue", r);
  return INT2NUM(r);
}

/* int free_queue(queue)
*/
static VALUE
wrap_snd_seq_free_queue(VALUE v_seq, VALUE v_qid)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  RRTS_DEREF_DIRTY(v_qid, @id);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_free_queue(%p, %d)\n", seq, NUM2INT(v_qid));
#endif
  const int r = snd_seq_free_queue(seq, NUM2INT(v_qid));
  return r < 0 ? INT2NUM(r) : Qnil;
}

/* int query_named_queue(name)
  Parameters:
    [name]    the queuename to locate

  Returns the queueid of the queue with given name or else nil.
*/
static VALUE
wrap_snd_seq_query_named_queue(VALUE v_seq, VALUE v_name)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_query_named_queue(seq, RSTRING_PTR(v_name));
  if (r == -EINVAL) return Qnil;
  if (r < 0) RAISE_MIDI_ERROR("queue query", r);
  return INT2NUM(r);
}

/* self start_queue(queue)
start the specified queue

Parameters:
  [queue] queueid or MidiQueue to start
  [ev]    optional event record (see snd_seq_control_queue)   CURRENTLY NOT SUPPORTED!

See also MidiQueue#start
*/
static VALUE
wrap_snd_seq_start_queue(VALUE v_seq, VALUE v_qid)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  RRTS_DEREF_DIRTY(v_qid, @id);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_start_queue(%p, %d, %d)\n", seq, NUM2INT(v_qid), 0);
#endif
  snd_seq_start_queue(seq, NUM2INT(v_qid), 0);
  return v_seq;
}

/* self stop_queue(q)

See #start_queue
*/
static VALUE
wrap_snd_seq_stop_queue(VALUE v_seq, VALUE v_qid)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_stop_queue(seq, NUM2INT(v_qid), 0);
  return Qnil;
}

/* AlsaQueueStatus_i queue_status(q [, status ])

obtain the running state of the queue

Parameters:
  [q]      queueid or MidiQueue to query
  [status] pointer to store the current status

Returns: status

If the +status+ parameter is omitted a new one is allocated
*/
static VALUE
wrap_snd_seq_get_queue_status(int argc, VALUE *v_params, VALUE v_seq)
{
  VALUE v_qid, v_status;
  rb_scan_args(argc, v_params, "11", &v_qid, &v_status);
  snd_seq_queue_status_t *status;
  if (NIL_P(v_status))
    {
      const int r = snd_seq_queue_status_malloc(&status);
      if (r < 0) RAISE_MIDI_ERROR("allocating queue_status", r);
      v_status = Data_Wrap_Struct(alsaQueueStatusClass, 0/*mark*/, snd_seq_queue_status_free/*free*/, status);
    }
  else
      Data_Get_Struct(v_status, snd_seq_queue_status_t, status);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_get_queue_status(seq, NUM2INT(v_qid), status);
  if (r < 0) RAISE_MIDI_ERROR("retrieving queue_status", r);
  return v_status;
}

/* int poll_descriptors_count(eventmask)

Parameters:
  [eventmask] the poll events to be checked (POLLIN or POLLOUT or combination)

 Get the number of poll descriptors. The polling events to be checked can be
 specified by the second argument.
 When both input and output are to be checked, pass POLLIN|POLLOUT
*/
static VALUE
wrap_snd_seq_poll_descriptors_count(VALUE v_seq, VALUE v_pollflags)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  return INT2NUM(snd_seq_poll_descriptors_count(seq, NUM2INT(v_pollflags)));
}

/* AlsaPollFds_i poll_descriptors([space, ]eventmask)

Get poll descriptors. If space is omitted snd_seq_poll_descriptors_count is used for that.

 Parameters:
    [space]      space in the poll descriptor array
    [eventmask]  polling events to be checked (POLLIN or POLLOUT or combination)

Get poll descriptors assigned to the sequencer handle. Since a sequencer handle can duplex streams,
you need to set which direction(s) is/are polled in events argument. When POLLIN bit is specified,
the incoming events to the ports are checked.

To check the returned poll-events, call #poll_descriptors_revents
instead of reading the pollfd structs directly.

Alsa examples call fds.poll(timeout_msec) since revents has a fixed and/or unknown timeout.
Whatever.
*/
static VALUE
wrap_snd_seq_poll_descriptors(int argc, VALUE *argv, VALUE v_seq)
{
  VALUE v_fdcount, v_pollflags;
  rb_scan_args(argc, argv, "11", &v_fdcount, &v_pollflags);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  size_t space;
  if (NIL_P(v_pollflags))
    {
      v_pollflags = v_fdcount;
      space = snd_seq_poll_descriptors_count(seq, NUM2INT(v_pollflags));
    }
  else
      space = NUM2UINT(v_fdcount);
  // 2
  struct pollfd * const fds = ALLOC_N(struct pollfd, space + sizeof(size_t));
  if (!fds) return INT2NUM(-ENOMEM);
  // 3
  *(size_t *)fds = space;
  /*const int fill = */ snd_seq_poll_descriptors(seq, (struct pollfd *)(((size_t *)fds) + 1), space, NUM2INT(v_pollflags));
//  return rb_ary_new3(2, INT2NUM(fill), v_room);
  return Data_Wrap_Struct(alsaPollFdsClass, 0/*mark*/, free/*free*/, fds);
}

/* boolarray poll_descriptors_revents(pollfds)

get returned events from poll descriptors

 Parameters:
   pollfds    AlsaPollFds_i, the poll descriptors

Returns boolean array or nil if there are no events.
The resulintg array holds an entry per filedescriptor, in the same order, holding true if
there was an event at that index. At least one of them must hold true.

However, you cannot specify a poll timeout, and the alsa examples all use poll instead!!
*/
static VALUE
wrap_snd_seq_poll_descriptors_revents(VALUE v_seq, VALUE v_fds)
{
  struct pollfd *fds;
  Data_Get_Struct(v_fds, struct pollfd, fds);
  const size_t nfds = *(size_t *)fds;
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  unsigned short revents[nfds];
  const int r = snd_seq_poll_descriptors_revents(seq, (struct pollfd *)(((size_t *)fds) + 1), nfds, revents);
  if (r < 0)
    RAISE_MIDI_ERROR("polling descriptors", r);
  bool located = false;
  for (size_t i = 0; i < nfds && !located; i++)
    located = revents[i];
  if (!located) return Qnil;
  VALUE v_revents = rb_ary_new2(nfds);
  for (size_t i = 0; i < nfds; i++)
    {
      const bool b = revents[i];
      rb_ary_store(v_revents, i, INT2BOOL(b));
    }
  return v_revents;
}

/* boolarray poll(timeout_msec)

Wrapper around poll (not ppoll -- currently)
Returns nil if no events where present
Returns an array of booleans where the index matches the polldescriptors passed.
At least one of them will be true.
*/
static VALUE
wrapPoll(VALUE v_descriptors, VALUE v_timeout_msec)
{
  struct pollfd *fds;
  Data_Get_Struct(v_descriptors, struct pollfd, fds);
  const size_t nfds = *(size_t *)fds;
  fds = (struct pollfd *)(((size_t *)fds) + 1);
  const int r = poll(fds, nfds, NUM2UINT(v_timeout_msec));
  if (r < 0)
    RAISE_MIDI_ERROR("polling descriptors", r);
  else if (r == 0)
    return Qnil;
  VALUE v_revents = rb_ary_new2(nfds);
  for (size_t i = 0; i < nfds; i++)
    rb_ary_store(v_revents, i, INT2BOOL(fds[i].revents));
  return v_revents;
}

/* int output_buffer_size

Obtains the size in bytes of output buffer. This buffer is used to store decoded
byte-stream of output events before transferring to sequencer.
*/
static VALUE
wrap_snd_seq_get_output_buffer_size(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  return UINT2NUM(snd_seq_get_output_buffer_size(seq));
}

/* int input_buffer_size

Obtains the size of input buffer in bytes. This buffer is used to read byte-stream
of input events from the sequencer.
*/
static VALUE
wrap_snd_seq_get_input_buffer_size(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  return UINT2NUM(snd_seq_get_input_buffer_size(seq));
}

/* input_buffer_size=(size)

Resize the input buffer.

Parameters:
  [size] the size of input buffer to be changed in bytes
*/
static VALUE
wrap_snd_seq_set_input_buffer_size(VALUE v_seq, VALUE v_sz)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_set_input_buffer_size(seq, NUM2UINT(v_sz));
  if (r) RAISE_MIDI_ERROR("setting input buffer size", r);
  return Qnil;
}

/* output_buffer_size=(size)

Resize the output buffer.

Parameters:
  [size] the size of output buffer to be changed in bytes
*/
static VALUE
wrap_snd_seq_set_output_buffer_size(VALUE v_seq, VALUE v_sz)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_set_output_buffer_size(seq, NUM2UINT(v_sz));
  if (r) RAISE_MIDI_ERROR("setting output buffer size", r);
  return Qnil;
}

/* AlsaPortInfo_i port_info(portid)
obtain the information of a port on the current client

Parameters:
  [portid] portid to get

Returns:
  AlsaPortInfo_i instance
*/
static VALUE
wrap_snd_seq_get_port_info(VALUE v_seq, VALUE v_portid)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_port_info_t * info;
  int r = snd_seq_port_info_malloc(&info);
  if (r < 0) RAISE_MIDI_ERROR("allocating port_info", r);
  r = snd_seq_get_port_info(seq, NUM2INT(v_portid), info);
  if (r < 0) RAISE_MIDI_ERROR("retrieving port_info", r);
  return Data_Wrap_Struct(alsaPortInfoClass, 0/*mark*/, snd_seq_port_info_free/*free*/, info);
}

/* AlsaPortInfo_i any_port_info(clientid, portid)
Return information about ports on any client
*/
static VALUE
wrap_snd_seq_get_any_port_info(VALUE v_seq, VALUE v_clientid, VALUE v_portid)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_port_info_t * info;
  int r = snd_seq_port_info_malloc(&info);
  if (r < 0) RAISE_MIDI_ERROR("allocating port_info", r);
  r = snd_seq_get_any_port_info(seq, NUM2INT(v_clientid), NUM2INT(v_portid), info);
  if (r < 0) RAISE_MIDI_ERROR("retrieving port_info", r);
  return Data_Wrap_Struct(alsaPortInfoClass, 0/*mark*/, snd_seq_port_info_free/*free*/, info);
}

/* self set_port_info(portid, port_info)

set the information of a port on the current client

Parameters:
  [portid]     port to be set
  [port_info]  AlsaPortInfo_i instance to be set

Returns:
  self
*/
static VALUE
wrap_snd_seq_set_port_info(VALUE v_seq, VALUE v_portid, VALUE v_portinfo)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_port_info_t * info;
  Data_Get_Struct(v_portinfo, snd_seq_port_info_t, info);
  const int r = snd_seq_set_port_info(seq, NUM2INT(v_portid), info);
  if (r < 0) RAISE_MIDI_ERROR("setting port_info", r);
  return v_seq;
}

/* AlsaClientPool_i client_pool([poolinfo])
obtain the pool information of the current client, allocates space if required
*/
static VALUE
wrap_snd_seq_get_client_pool(int argc, VALUE *argv, VALUE v_seq)
{
  VALUE v_pool;
  rb_scan_args(argc, argv, "01", &v_pool);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_client_pool_t *pool;
  if (NIL_P(v_pool))
    {
      const int r = snd_seq_client_pool_malloc(&pool);
      if (r < 0) RAISE_MIDI_ERROR("allocating client_pool", r);
      v_pool = Data_Wrap_Struct(alsaClientPoolClass, 0/*mark*/, snd_seq_client_pool_free/*free*/, pool);
    }
  else
      Data_Get_Struct(v_pool, snd_seq_client_pool_t, pool);
  const int r = snd_seq_get_client_pool(seq, pool);
  if (r < 0) RAISE_MIDI_ERROR("retrieving client pool", r);
  return v_pool;
}

/* client_pool=(poolinfo)
set the pool information
*/
static VALUE
wrap_snd_seq_set_client_pool(VALUE v_seq, VALUE v_pool)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_client_pool_t * info;
  Data_Get_Struct(v_pool, snd_seq_client_pool_t, info);
  const int r = snd_seq_set_client_pool(seq, info);
  if (r < 0) RAISE_MIDI_ERROR("setting client_pool", r);
  return Qnil;
}

/* client_pool_output=(size)
change the output pool size of the current client
*/
static VALUE
wrap_snd_seq_set_client_pool_output(VALUE v_seq, VALUE v_sz)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_set_client_pool_output(seq, NUM2UINT(v_sz));
  if (r < 0) RAISE_MIDI_ERROR("setting client pool output size", r);
  return Qnil;
}

/* int client_pool_output_room=(size)
change the output room size of the current client
*/
static VALUE
wrap_snd_seq_set_client_pool_output_room(VALUE v_seq, VALUE v_sz)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_set_client_pool_output_room(seq, NUM2UINT(v_sz));
  if (r < 0) RAISE_MIDI_ERROR("setting client pool output room", r);
  return Qnil;
}

/* client_pool_input=(size)
change the input pool size of the current client
*/
static VALUE
wrap_snd_seq_set_client_pool_input(VALUE v_seq, VALUE v_sz)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_set_client_pool_input(seq, NUM2UINT(v_sz));
  if (r < 0) RAISE_MIDI_ERROR("setting client pool input size", r);
  return Qnil;
}

/* self reset_pool_output
*/
static VALUE
wrap_snd_seq_reset_pool_output(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_reset_pool_output(seq);
  if (r < 0) RAISE_MIDI_ERROR("resetting client pool output", r);
  return v_seq;
}

/* self reset_pool_input
*/
static VALUE
wrap_snd_seq_reset_pool_input(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_reset_pool_input(seq);
  if (r < 0) RAISE_MIDI_ERROR("resetting client pool input", r);
  return v_seq;
}

/* AlsaSystemInfo_i seq_system_info([info])
obtain the sequencer system information, if no buffer is passed, it is allocated
*/
static VALUE
wrap_snd_seq_system_info(int argc, VALUE *argv, VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  VALUE v_info;
  rb_scan_args(argc, argv, "01", &v_info);
  snd_seq_system_info_t *info;
  if (NIL_P(v_info))
    {
      const int r = snd_seq_system_info_malloc(&info);
      if (r < 0) RAISE_MIDI_ERROR("allocating syteminfo", r);
      v_info = Data_Wrap_Struct(alsaSystemInfoClass, 0/*mark*/, snd_seq_system_info_free/*free*/,
                                info);
    }
  else
      Data_Get_Struct(v_info, snd_seq_system_info_t, info);
  const int r = snd_seq_system_info(seq, info);
  if (r < 0) RAISE_MIDI_ERROR("retrieving system info", r);
  return v_info;
}

/*
Wrapper around snd_seq_t. A sequencer is basically a client.
Create one using Driver#seq_open
*/
void alsa_seq_init()
{
  WRAP_CONSTANT(POLLIN);
  WRAP_CONSTANT(POLLOUT);
  WRAP_CONSTANT(MIDI_BYTES_PER_SEC);
  // W RAP_CONSTANT(SND_SEQ_DLSYM_VERSION)  UNDEFINED!!
  WRAP_CONSTANT(SND_SEQ_ADDRESS_UNKNOWN);
  WRAP_CONSTANT(SND_SEQ_ADDRESS_SUBSCRIBERS);
  WRAP_CONSTANT(SND_SEQ_ADDRESS_BROADCAST);
  WRAP_CONSTANT(SND_SEQ_CLIENT_SYSTEM);
  WRAP_CONSTANT(SND_SEQ_PORT_SYSTEM_TIMER);
  WRAP_CONSTANT(SND_SEQ_PORT_SYSTEM_ANNOUNCE);
  WRAP_CONSTANT(SND_SEQ_TYPE_HW); //       hardware
  WRAP_CONSTANT(SND_SEQ_TYPE_SHM); //       shared memory (NYI)
  WRAP_CONSTANT(SND_SEQ_TYPE_INET); //        network (NYI)
  alsaSequencerClass = rb_define_class_under(alsaDriver, "AlsaSequencer_i", rb_cObject);
  alsaPollFdsClass = rb_define_class_under(alsaDriver, "AlsaPollFds_i", rb_cObject);
  rb_define_method(alsaSequencerClass, "close", RUBY_METHOD_FUNC(wrap_snd_seq_close), 0);
  rb_define_method(alsaSequencerClass, "name", RUBY_METHOD_FUNC(wrap_snd_seq_name), 0);
  rb_define_method(alsaSequencerClass, "client_id", RUBY_METHOD_FUNC(wrap_snd_seq_client_id), 0);
  rb_define_method(alsaSequencerClass, "client_name=", RUBY_METHOD_FUNC(wrap_snd_seq_set_client_name), 1);
  rb_define_method(alsaSequencerClass, "create_simple_port", RUBY_METHOD_FUNC(wrap_snd_seq_create_simple_port), 3);
  rb_define_method(alsaSequencerClass, "create_port", RUBY_METHOD_FUNC(wrap_snd_seq_create_port), 1);
  rb_define_method(alsaSequencerClass, "delete_port", RUBY_METHOD_FUNC(wrap_snd_seq_delete_port), 1);
  rb_define_method(alsaSequencerClass, "nonblock", RUBY_METHOD_FUNC(wrap_snd_seq_nonblock), -1);
  rb_define_method(alsaSequencerClass, "subscribe_port", RUBY_METHOD_FUNC(wrap_snd_seq_subscribe_port), 1);
  rb_define_method(alsaSequencerClass, "unsubscribe_port", RUBY_METHOD_FUNC(wrap_snd_seq_unsubscribe_port), 1);
  rb_define_method(alsaSequencerClass, "delete_simple_port", RUBY_METHOD_FUNC(wrap_snd_seq_delete_simple_port), 1);
  // using -3 gives /rrecordmidi.rb:290:in `connect_from': too many arguments(-3) (ArgumentError)
  // This is Correct according to Matz, since only -1 and -2 are allowed and they have special meaning!!
  rb_define_method(alsaSequencerClass, "connect_from", RUBY_METHOD_FUNC(wrap_snd_seq_connect_from), -1);
  rb_define_method(alsaSequencerClass, "connect_to", RUBY_METHOD_FUNC(wrap_snd_seq_connect_to), -1);
  rb_define_method(alsaSequencerClass, "disconnect_from", RUBY_METHOD_FUNC(wrap_snd_seq_disconnect_from), -1);
  rb_define_method(alsaSequencerClass, "disconnect_to", RUBY_METHOD_FUNC(wrap_snd_seq_disconnect_to), -1);
  rb_define_method(alsaSequencerClass, "parse_address", RUBY_METHOD_FUNC(wrap_snd_seq_parse_address), 1);
  rb_define_method(alsaSequencerClass, "sync_output_queue", RUBY_METHOD_FUNC(wrap_snd_seq_sync_output_queue), 0);
  rb_define_method(alsaSequencerClass, "drain_output", RUBY_METHOD_FUNC(wrap_snd_seq_drain_output), 0);
  rb_define_method(alsaSequencerClass, "event_input", RUBY_METHOD_FUNC(wrap_snd_seq_event_input), 0);
  rb_define_method(alsaSequencerClass, "event_output", RUBY_METHOD_FUNC(wrap_snd_seq_event_output), 1);
  rb_define_method(alsaSequencerClass, "event_output_buffer", RUBY_METHOD_FUNC(wrap_snd_seq_event_output_buffer), 1);
  rb_define_method(alsaSequencerClass, "event_output_direct", RUBY_METHOD_FUNC(wrap_snd_seq_event_output_direct), 1);
  rb_define_method(alsaSequencerClass, "event_input_pending", RUBY_METHOD_FUNC(wrap_snd_seq_event_input_pending), -1);
  rb_define_method(alsaSequencerClass, "drop_input", RUBY_METHOD_FUNC(wrap_snd_seq_drop_input), 0);
  rb_define_method(alsaSequencerClass, "drop_input_buffer", RUBY_METHOD_FUNC(wrap_snd_seq_drop_input_buffer), 0);
  rb_define_method(alsaSequencerClass, "queue_info", RUBY_METHOD_FUNC(wrap_snd_seq_get_queue_info), -1);
  rb_define_method(alsaSequencerClass, "set_queue_info", RUBY_METHOD_FUNC(wrap_snd_seq_set_queue_info), 2);
  rb_define_method(alsaSequencerClass, "queue_status", RUBY_METHOD_FUNC(wrap_snd_seq_get_queue_status), -1);
  rb_define_method(alsaSequencerClass, "set_queue_tempo", RUBY_METHOD_FUNC(wrap_snd_seq_set_queue_tempo), 2);
  rb_define_method(alsaSequencerClass, "create_queue", RUBY_METHOD_FUNC(wrap_snd_seq_create_queue), 1);
  rb_define_method(alsaSequencerClass, "free_queue", RUBY_METHOD_FUNC(wrap_snd_seq_free_queue), 1);
  rb_define_method(alsaSequencerClass, "start_queue", RUBY_METHOD_FUNC(wrap_snd_seq_start_queue), 1);
  rb_define_method(alsaSequencerClass, "stop_queue", RUBY_METHOD_FUNC(wrap_snd_seq_stop_queue), 1);
  rb_define_method(alsaSequencerClass, "query_named_queue", RUBY_METHOD_FUNC(wrap_snd_seq_query_named_queue), 1);
  rb_define_method(alsaSequencerClass, "next_client", RUBY_METHOD_FUNC(wrap_snd_seq_query_next_client), 1);
  rb_define_method(alsaSequencerClass, "next_port", RUBY_METHOD_FUNC(wrap_snd_seq_query_next_port), 1);
  rb_define_method(alsaSequencerClass, "query_next_client", RUBY_METHOD_FUNC(wrap_snd_seq_query_next_client), 1);
  rb_define_method(alsaSequencerClass, "query_next_port", RUBY_METHOD_FUNC(wrap_snd_seq_query_next_port), 1);
  rb_define_method(alsaSequencerClass, "alloc_named_queue", RUBY_METHOD_FUNC(wrap_snd_seq_alloc_named_queue), 1);
  rb_define_method(alsaSequencerClass, "poll_descriptors_count", RUBY_METHOD_FUNC(wrap_snd_seq_poll_descriptors_count), 1);
  rb_define_method(alsaSequencerClass, "poll_descriptors", RUBY_METHOD_FUNC(wrap_snd_seq_poll_descriptors), -1);
  rb_define_method(alsaSequencerClass, "poll_descriptors_revents", RUBY_METHOD_FUNC(wrap_snd_seq_poll_descriptors_revents), 1);
  rb_define_method(alsaSequencerClass, "output_buffer_size", RUBY_METHOD_FUNC(wrap_snd_seq_get_output_buffer_size), 0);
  rb_define_method(alsaSequencerClass, "input_buffer_size", RUBY_METHOD_FUNC(wrap_snd_seq_get_input_buffer_size), 0);
  rb_define_method(alsaSequencerClass, "output_buffer_size=", RUBY_METHOD_FUNC(wrap_snd_seq_set_output_buffer_size), 1);
  rb_define_method(alsaSequencerClass, "input_buffer_size=", RUBY_METHOD_FUNC(wrap_snd_seq_set_input_buffer_size), 1);
  rb_define_method(alsaSequencerClass, "port_info", RUBY_METHOD_FUNC(wrap_snd_seq_get_port_info), 1);
  rb_define_method(alsaSequencerClass, "any_port_info", RUBY_METHOD_FUNC(wrap_snd_seq_get_any_port_info), 2);
  rb_define_method(alsaSequencerClass, "set_port_info", RUBY_METHOD_FUNC(wrap_snd_seq_set_port_info), 2);
  rb_define_method(alsaPollFdsClass, "poll", RUBY_METHOD_FUNC(wrapPoll), 1);
  rb_define_method(alsaSequencerClass, "remove_events", RUBY_METHOD_FUNC(wrap_snd_seq_remove_events), -1);
  rb_define_method(alsaSequencerClass, "client_pool", RUBY_METHOD_FUNC(wrap_snd_seq_get_client_pool), -1);
  rb_define_method(alsaSequencerClass, "client_pool=", RUBY_METHOD_FUNC(wrap_snd_seq_set_client_pool), 1);
  rb_define_method(alsaSequencerClass, "client_pool_output=", RUBY_METHOD_FUNC(wrap_snd_seq_set_client_pool_output), 1);
  rb_define_method(alsaSequencerClass, "client_pool_output_room=", RUBY_METHOD_FUNC(wrap_snd_seq_set_client_pool_output_room), 1);
  rb_define_method(alsaSequencerClass, "client_pool_input=", RUBY_METHOD_FUNC(wrap_snd_seq_set_client_pool_input), 1);
  rb_define_method(alsaSequencerClass, "reset_pool_output", RUBY_METHOD_FUNC(wrap_snd_seq_reset_pool_output), 0);
  rb_define_method(alsaSequencerClass, "reset_pool_input", RUBY_METHOD_FUNC(wrap_snd_seq_reset_pool_input), 0);
  rb_define_method(alsaSequencerClass, "system_info", RUBY_METHOD_FUNC(wrap_snd_seq_system_info), -1);
#if defined(DEBUG)
  rb_define_method(alsaSequencerClass, "dump_notes=", RUBY_METHOD_FUNC(AlsaSequencer_set_dump_notes), 1);
#endif
}
