
// If changed do:         make
// To create Makefile:    ruby ./extruby.rb

// #define DUMP_API

#pragma implementation

#if defined(DUMP_API)
#define DUMP_STREAM stderr
#endif

#include "alsa_seq.h"
#include "alsa_midi.h"
#include "alsa_midi_event.h"
#include "alsa_midi_queue.h"
#include "alsa_midi_client.h"
#include <ruby/dl.h>
#include <alsa/asoundlib.h>

VALUE alsaSequencerClass;
static VALUE alsaPollFdsClass;

/*
int AlsaSequencer_i#close

Close the sequencer.

Returns:
nil on success otherwise a negative error code

Closes the sequencer client and releases its resources. After a client is closed, an event with
SND_SEQ_EVENT_CLIENT_EXIT is broadcast to announce port. The connection between other clients are disconnected.
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

/*
string AlsaSequencer_i#name
get identifier of sequencer handle

Returns:
ASCII identifier of sequencer handle

Returns the ASCII identifier of the given sequencer handle. It's the same identifier specified in snd_seq_open().
*/

static VALUE
wrap_snd_seq_name(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  return rb_str_new2(snd_seq_name(seq));
}

/* int AlsaSequencer_i#client_id
Get the client id.

Returns:
the client id

Returns the id of the specified client. If an error occurs, function raises AlsaMidiError
A client id is necessary to inquiry or to set the client information. A user client is assigned from 128 to 191.
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
  if (r < 0) RAISE_MIDI_ERROR(r);
  return INT2NUM(r);
}

/* AlsaSequencer_i#nonblock=(nonblock = true)
Set nonblock mode.

Parameters:
nonblock        false = block, true = nonblock mode

Returns:
May raise AlsaMidiError

Change the blocking mode of the given client. In block mode, the client falls into sleep when it fills the output memory
pool with full events. The client will be woken up after a certain amount of free space becomes available.
*/
static VALUE
wrap_snd_seq_nonblock(int argc, VALUE *v_params, VALUE v_seq)
{
  VALUE v_bool;
  rb_scan_args(argc, v_params, "01", &v_bool);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_nonblock(seq, NIL_P(v_bool) ? 1 : BOOL2INT(v_bool));
  if (r) RAISE_MIDI_ERROR(r);
  return Qnil;
}

/* self AlsaSequencer_i#set_client_name(name)
set client name

Parameters:
name    name string

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
  if (r) RAISE_MIDI_ERROR(r);
  return v_seq;
}

/*
port_info AlsaSequencer_i#create_port(port_info))

                                        create a sequencer port on the current client

                                        Parameters:
                                        port_info    port information for the new port

       Returns: port_info

        Creates a sequencer port on the current client. The attributes of created port is specified in info argument.

        The client field in info argument is overwritten with the current client id. The port id to be created can be
        specified via snd_seq_port_info_set_port_specified. You can get the created port id by reading the port pointer via
        snd_seq_port_info_get_port.

        Each port has the capability bit-masks to specify the access capability of the port from other clients.
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

        A port may contain specific midi channels, midi voices and synth voices. These values could be zero as default.
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
  if (r < 0) RAISE_MIDI_ERROR(r);
  return v_portinfo;
}

/*
int AlsaSequencer_i#create_simple_port(name, caps, type)

create a port - simple version

Parameters:
seq     sequencer handle
name    the name of the port
caps    capability bits
type    type bits
Returns:
the created port number.
Creates a port with the given capability and type bits.
Each port has the capability bit-masks to specify the access capability of the port from other clients. The capability bit flags are defined as follows:

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
  if (r < 0) RAISE_MIDI_ERROR(r);
  return INT2NUM(r);
}

/*
int AlsaSequencer_i#delete_simple_port(port)
delete the port
Parameters:
port    port id
Returns:
nil on success or negative error code
*/
static VALUE
wrap_snd_seq_delete_simple_port(VALUE v_seq, VALUE v_portid)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_delete_simple_port(%p, %d)\n", seq, NUM2INT(v_portid));
#endif
  const int r = snd_seq_delete_simple_port(seq, NUM2INT(v_portid));
  return r ? INT2NUM(r) : Qnil;
}

/* event, more event_input
retrieve an event from sequencer

Returns:

Obtains an input event from sequencer. The event is created via snd_seq_create_event(), and its pointer is stored on ev argument.
This function firstly receives the event byte-stream data from sequencer as much as possible at once. Then it retrieves
the first event record and store the pointer on ev. By calling this function sequentially, events are extracted from
the input buffer.
If there is no input from sequencer, function falls into sleep in blocking mode until an event is received,
or returns nil in non-blocking mode. Occasionally, it may raise ENOSPC error. This means that the input
FIFO of sequencer overran, and some events are lost. Once this error is returned, the input FIFO is cleared automatically.

Function returns the event plus a boolean indicating more bytes remain in the input buffer
Application can determine from the returned value whether to call input once more or not,
if there's more data it will probably(!) not block, even in blocking mode.
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
  // according to mailing lists, these need NOT be freed. And it can't even since event_free is deprecated
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
  return rb_ary_new3(2, Data_Wrap_Struct(alsaMidiEventClass, 0/*mark*/, 0/*free*/, ev), INT2BOOL(r > 0));
}

/*
int AlsaSequencer_i#event_output(ev)

output an event

Parameters:
              ev      AlsaMidiEvent_i or MidiEvent to be output

Returns:
  the number of remaining events

An event is once expanded on the output buffer. The output buffer will be drained automatically if it becomes full.

If events remain unprocessed on output buffer before drained, the size of total byte data on output buffer is
returned. If the output buffer is empty, this returns zero.
*/

static VALUE
wrap_snd_seq_event_output(VALUE v_seq, VALUE v_ev)
{
  snd_seq_event_t *ev;
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  Data_Get_Struct(v_ev, snd_seq_event_t, ev);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_event_output(%p, %p)\n", seq, ev);
#endif
  const int r = snd_seq_event_output(seq, ev);
  if (r < 0) RAISE_MIDI_ERROR(r);
  return INT2NUM(r);
}

/*
bool AlsaSequencer_i#query_next_client(info)
query the next client
Parameters:
info    query pattern and result
Queries the next client. The search begins at the client with an id one greater than client field in info.
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

/*
bool AlsaSequencer_i#query_next_port info
query the next matching port
Parameters:
info    query pattern and result
Queries the next matching port on the client specified in info argument. The search begins at the next port specified in
port field of info argument. For finding the first port at a certain client, give -1.
If a matching port is found, its attributes are stored on info and function returns true. Otherwise,
false.
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
  if (r < 0) RAISE_MIDI_ERROR(r);
  return Qtrue;
}

/*
int AlsaSequencer_i#alloc_named_queue   name

allocate a queue with the specified name

 Parameters:
   name    the name of the new queue

 Returns:
   the queue id (zero or positive) on success
*/
static VALUE
wrap_snd_seq_alloc_named_queue(VALUE v_seq, VALUE v_name)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_alloc_named_queue(seq, RSTRING_PTR(v_name));
  if (r < 0) RAISE_MIDI_ERROR(r);
  return INT2NUM(r);
}

/*
sub AlsaSequencer_i#subscribe_port sub
subscribe a port connection
Parameters:
sub     subscription information
Subscribes a connection between two ports. The subscription information is stored in sub argument.
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
  if (r < 0) RAISE_MIDI_ERROR(r);
  return v_port_subs;
}

/* int AlsaSequencer_i#unsubscribe_port(port_sub)
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
RRTS_DEREF(v_myportid, port)

/*
AlsaSequencer_i#connect_from(myport, src_client, src_port)
AlsaSequencer_i#connect_from(myport, [src_client, src_port])
simple subscription (w/o exclusive & time conversion)
Parameters:
myport  the port id as receiver, or the MidiPort (something with a 'port' method)
src_client      sender client id
src_port        sender port id
Connect from the given sender client:port to the given destination port in the current client.
*/
// where destclient = current client, and myportid = dstportid
static VALUE
wrap_snd_seq_connect_from(int argc, VALUE *v_params, VALUE v_seq)
{
  fprintf(stderr, "connect_from(argc=%d)\n", argc);
  FETCH_CONNECTION_ADDRESSES(src);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int src_cid = NUM2INT(v_src_clientid), src_pid = NUM2INT(v_src_portid);
  const int r = snd_seq_connect_from(seq, NUM2INT(v_myportid), src_cid, src_pid);
  if (r) RAISE_MIDI_ERROR_FMT3("cannot connect from port %d:%d - %s", src_cid, src_pid, snd_strerror(r));
  return Qnil;
}

/*
AlsaSequencer_i#connect_to(myport, dest_client, dest_port)
AlsaSequencer_i#connect_to(myport, [dest_client, dest_port])
simple subscription (w/o exclusive & time conversion)
Parameters:
myport  the port id as sender, but it may also respond to :port
dest_client     destination client id
dest_port       destination port id
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
  return Qnil;
}

/*
AlsaSequencer_i#disconnect_from(myport, src_client, src_port)
AlsaSequencer_i#disconnect_from(myport, [src_client, src_port])
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

/*
AlsaSequencer_i#disconnect_to(myport, dest_client, dest_port)
AlsaSequencer_i#disconnect_to(myport, [dest_client, dest_port])
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

/*
clientid, portid AlsaSequencer_i::parse_address(addr, arg)
parse the given string and get the sequencer address
Parameters:
addr    the address pointer to be returned
arg     the string to be parsed
Returns:
clientid + portid on success or it raises a AlsaMidiError
This function parses the sequencer client and port numbers from the given string.
The client and port tokes are separated by either colon or period, e.g. 128:1. When seq is not NULL,
the function accepts also a client name not only digit numbers.

The arguments could be '20:2' or 'MIDI2:0' etc.  Portnames are not understood!
*/
static VALUE
wrap_snd_seq_parse_address(VALUE v_seq, VALUE v_arg)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_addr_t ret;
  const char *const arg = StringValuePtr(v_arg);
  const int r = snd_seq_parse_address(seq, &ret, arg);
  if (r < 0) RAISE_MIDI_ERROR_FMT2("Invalid port %s - %s", arg, snd_strerror(r));
  return rb_ary_new3(2, INT2NUM(ret.client), INT2NUM(ret.port));
}

/*
AlsaSequencer_i#sync_output_queue
wait until all events are processed
This function waits until all events of this client are processed.
*/
static VALUE
wrap_snd_seq_sync_output_queue(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_sync_output_queue(seq);
  if (r) RAISE_MIDI_ERROR(r);
  return Qnil;
}

/*
int AlsaSequencer_i#drain_output
drain output buffer to sequencer
Returns:
0 when all events are drained and sent to sequencer. When events
still remain on the buffer, the byte size of remaining events are returned. On error a AlsaMidiError is raised.
This function drains all pending events on the output buffer. The function returns immediately after
the events are sent to the queues regardless whether the events are processed or not. To get synchronization with the
all event processes, use snd_seq_sync_output_queue() after calling this function.
*/
static VALUE
wrap_snd_seq_drain_output(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_drain_output(seq);
  if (r < 0) RAISE_MIDI_ERROR(r);
  return INT2NUM(r);
}

/*
int AlsaSequencer_i#input_pending(fetch_sequencer_fifo = true)

 check events in input buffer

 Returns:
  the byte size of remaining input events on input buffer.

 If events remain on the input buffer of user-space, function returns the total byte size of events on it.
 If fetch_sequencer_fifo argument is true, this function checks the presence of events on sequencer FIFO
 When events exist, they are transferred to the input buffer, and the number of received events are returned.
 If fetch_sequencer argument is zero and no events remain on the input buffer, function simply returns zero.
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

/*
AlsaSequencer_i#drop_input
clear input buffer and and remove events in sequencer queue

*/
static VALUE
wrap_snd_seq_drop_input(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_drop_input(seq);
  return Qnil;
}

/*
nil AlsaSequencer_i#drop_input_buffer

remove all events on user-space input FIFO

*/
static VALUE
wrap_snd_seq_drop_input_buffer(VALUE v_seq)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_drop_input_buffer(seq);
  return Qnil;
}

/*
self AlsaSequencer_i#set_queue_info(qid, info)

change the queue attributes

                                        Parameters:
                                        qid       queue id to change
                                        info    information changed
*/
static VALUE
wrap_snd_seq_set_queue_info(VALUE v_seq, VALUE v_qid, VALUE v_qi)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_queue_info_t *qi;
  Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_set_queue_info(%p, %d, %p)\n", seq, NUM2INT(v_qid), qi);
#endif
  const int r = snd_seq_set_queue_info(seq, NUM2INT(v_qid), qi);
  if (r) RAISE_MIDI_ERROR(r);
  return v_seq;
}

/*
self AlsaSequencer_i#set_queue_tempo(q, tempo)

set the tempo of the queue

                                        Parameters:
                                        q       queue id to change the tempo
                                        tempo   tempo information

*/
static VALUE
wrap_snd_seq_set_queue_tempo(VALUE v_seq, VALUE v_qid, VALUE v_tempo)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  RRTS_DEREF_DIRTY(v_tempo, @handle);
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

/*
info AlsaSequencer_i#queue_info q [, info]

obtain queue attributes

Parameters:
  q       queue id to query
  info    room for information returned

Returns: info
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
      if (r < 0) RAISE_MIDI_ERROR(r);
      v_qi = Data_Wrap_Struct(alsaQueueInfoClass, 0/*mark*/, snd_seq_queue_info_free/*free*/, qi);
    }
  else
      Data_Get_Struct(v_qi, snd_seq_queue_info_t, qi);
  const int r = snd_seq_get_queue_info(seq, NUM2INT(v_qid), qi);
  if (r < 0) RAISE_MIDI_ERROR(r);
  return v_qi;
}

/*
int AlsaSequencer_i#create_queue info

create a queue

Parameters:
         info    queue information to initialize

Returns:
  the queue id (zero or positive) on success
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
  if (r < 0) RAISE_MIDI_ERROR(r);
  return INT2NUM(r);
}

// int free_queue(qid)
static VALUE
wrap_snd_seq_free_queue(VALUE v_seq, VALUE v_qid)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_free_queue(%p, %d)\n", seq, NUM2INT(v_qid));
#endif
  const int r = snd_seq_free_queue(seq, NUM2INT(v_qid));
  return r < 0 ? INT2NUM(r) : Qnil;
}

/*
int AlsaSequencer_i#query_named_queue   name

                                        query the matching queue with the specified name

                                        Parameters:
                                        name    the name string to query

                                        Returns:
                                        the queue id if found or nil if not found.  (FIXME!!!)
                                        Searches the matching queue with the specified name string.
*/
static VALUE
wrap_snd_seq_query_named_queue(VALUE v_seq, VALUE v_name)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_query_named_queue(seq, RSTRING_PTR(v_name));
  if (r == -ENOENT) /* ?????????????????????? FIXME */ return Qnil;
  if (r < 0) RAISE_MIDI_ERROR(r);
  return INT2NUM(r);
}

/*
self AlsaSequencer_i#start_queue q
== snd_seq_control_queue(seq, q, SND_SEQ_EVENT_START, 0[, ev = NULL])

start the specified queue

Parameters:
q       queue id to start
ev      optional event record (see snd_seq_control_queue)   CURRENTLY NOT SUPPORTED!
*/
static VALUE
wrap_snd_seq_start_queue(VALUE v_seq, VALUE v_qid)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
#if defined(DUMP_API)
  fprintf(DUMP_STREAM, "snd_seq_start_queue(%p, %d, %d)\n", seq, NUM2INT(v_qid), 0);
#endif
  snd_seq_start_queue(seq, NUM2INT(v_qid), 0);
  return v_seq;
}

// AlsaSequencer_i#stop_queue qid
static VALUE
wrap_snd_seq_stop_queue(VALUE v_seq, VALUE v_qid)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  snd_seq_stop_queue(seq, NUM2INT(v_qid), 0);
  return Qnil;
}



/*
status AlsaSequencer_i#queue_status    q [, status ]

obtain the running state of the queue

Parameters:
  q       queue id to query
  status  pointer to store the current status

Returns: status
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
      if (r < 0) RAISE_MIDI_ERROR(r);
      v_status = Data_Wrap_Struct(alsaQueueStatusClass, 0/*mark*/, snd_seq_queue_status_free/*free*/, status);
    }
  else
      Data_Get_Struct(v_status, snd_seq_queue_status_t, status);
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  const int r = snd_seq_get_queue_status(seq, NUM2INT(v_qid), status);
  if (r < 0) RAISE_MIDI_ERROR(r);
  return v_status;
}

/*
int AlsaSequencer_i#poll_descriptors_count  events

Returns the number of poll descriptors.

                                                Parameters:
                                                events  the poll events to be checked (POLLIN and POLLOUT)

                                                Returns:
                                                the number of poll descriptors.

 Get the number of poll descriptors. The polling events to be checked can be specified by the second argument.
 When both input and output are checked, pass POLLIN|POLLOUT
*/

static VALUE
wrap_snd_seq_poll_descriptors_count(VALUE v_seq, VALUE v_pollflags)
{
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  return INT2NUM(snd_seq_poll_descriptors_count(seq, NUM2INT(v_pollflags)));
}

/*
pollfds AlsaSequencer_i#poll_descriptors(space, events
                                        )

Get poll descriptors.

                                        Parameters:
                                        space   space in the poll descriptor array
                                        events  polling events to be checked (POLLIN and POLLOUT)

Returns:
  descriptors

Get poll descriptors assigned to the sequencer handle. Since a sequencer handle can duplex streams,
you need to set which direction(s) is/are polled in events argument. When POLLIN bit is specified,
the incoming events to the ports are checked.

To check the returned poll-events, call snd_seq_poll_descriptors_revents() instead of reading the pollfd structs directly.
*/

static VALUE
wrap_snd_seq_poll_descriptors(VALUE v_seq, VALUE v_fdcount, VALUE v_pollflags)
{
  // 1
  const size_t space = NUM2UINT(v_fdcount); // rb_funcall2(v_pollfds, rb_intern("length")));
  // 2
  struct pollfd * const fds = ALLOC_N(struct pollfd, space + sizeof(size_t));
  if (!fds) return INT2NUM(-ENOMEM);
  // 3
  snd_seq_t *seq;
  Data_Get_Struct(v_seq, snd_seq_t, seq);
  *(size_t *)fds = space;
  /*const int fill = */ snd_seq_poll_descriptors(seq, (struct pollfd *)(((size_t *)fds) + 1), space, NUM2INT(v_pollflags));
//  return rb_ary_new3(2, INT2NUM(fill), v_room);
  return Data_Wrap_Struct(alsaPollFdsClass, 0/*mark*/, free/*free*/, fds);
}

/*
intarray AlsaSequencer_i#poll_descriptors_revents pollfds

get returned events from poll descriptors

                                                Parameters:
                                                pollfds    array of poll descriptors

Returns:
  revents array or negative int on failure.
  The revents array holds an entry per fd, holding the fd itself or 0
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
  VALUE v_revents = rb_ary_new2(nfds);
  if (r < 0) RAISE_MIDI_ERROR(r);
  else for (size_t i = 0; i < nfds; i++)
    rb_ary_store(v_revents, i, UINT2NUM(revents[i]));
  return v_revents;
}

void alsa_seq_init()
{
  WRAP_CONSTANT(POLLIN);
  WRAP_CONSTANT(POLLOUT);
  // W RAP_CONSTANT(SND_SEQ_DLSYM_VERSION)  UNDEFINED!!
  WRAP_CONSTANT(SND_SEQ_ADDRESS_UNKNOWN);
  WRAP_CONSTANT(SND_SEQ_ADDRESS_SUBSCRIBERS);
  WRAP_CONSTANT(SND_SEQ_ADDRESS_BROADCAST);
  WRAP_CONSTANT(SND_SEQ_CLIENT_SYSTEM);
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
  rb_define_method(alsaSequencerClass, "alloc_named_queue", RUBY_METHOD_FUNC(wrap_snd_seq_alloc_named_queue), 1);
  rb_define_method(alsaSequencerClass, "poll_descriptors_count", RUBY_METHOD_FUNC(wrap_snd_seq_poll_descriptors_count), 1);
  rb_define_method(alsaSequencerClass, "poll_descriptors", RUBY_METHOD_FUNC(wrap_snd_seq_poll_descriptors), 2);
  rb_define_method(alsaSequencerClass, "poll_descriptors_revents", RUBY_METHOD_FUNC(wrap_snd_seq_poll_descriptors_revents), 1);
}
