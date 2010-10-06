=begin
================================================================
        aconnect - control subscriptions
                ver.0.1.3
        Copyright (C) 1999-2000 Takashi Iwai
================================================================
=end

=begin
/*
 * connect / disconnect two subscriber ports
 *   ver.0.1.3
 *
 * Copyright (C) 1999 Takashi Iwai
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 */
=end

require 'rrts/driver/alsa_midi'

include RRTS::Driver

# translation stub....
def _(x)
  x
end

def usage
  printf(_("rconnect - ALSA sequencer connection manager\n"));
  printf(_("Copyright (C) 1999-2000 Takashi Iwai\n"));
  printf(_("Copyright (c) 2010 Eugene Brazwick\n"));
  printf(_("Usage:\n"));
  printf(_(" * Connection/disconnection between two ports\n"));
  printf(_("   aconnect [-options] sender receiver\n"));
  printf(_("     sender, receiver = client:port pair\n"));
  printf(_("     -d,--disconnect     disconnect\n"));
  printf(_("     -e,--exclusive      exclusive connection\n"));
  printf(_("     -r,--real #         convert real-time-stamp on queue\n"));
  printf(_("     -t,--tick #         convert tick-time-stamp on queue\n"));
  printf(_(" * List connected ports (no subscription action)\n"));
  printf(_("   aconnect -i|-o [-options]\n"));
  printf(_("     -i,--input          list input (readable) ports\n"));
  printf(_("     -o,--output         list output (writable) ports\n"));
  printf(_("     -l,--list           list current connections of each port\n"));
  printf(_(" * Remove all exported connections\n"));
  printf(_("     -x, --removeall\n"));
end

# /*
#  * check permission (capability) of specified port
#  */


LIST_INPUT      = 1
LIST_OUTPUT     = 2

def perm_ok(pinfo, bits)
  (pinfo.capability & bits) == bits
end

def check_permission pinfo, perm
  catch :ok do
    if (perm != 0)
      if (perm & LIST_INPUT) != 0
        throw :ok if (perm_ok(pinfo, SND_SEQ_PORT_CAP_READ|SND_SEQ_PORT_CAP_SUBS_READ))
      end
      if (perm & LIST_OUTPUT) != 0
        throw :ok if (perm_ok(pinfo, SND_SEQ_PORT_CAP_WRITE|SND_SEQ_PORT_CAP_SUBS_WRITE))
      end
      return false
    end
  end
  (pinfo.capability & SND_SEQ_PORT_CAP_NO_EXPORT) == 0
end

# /*
#  * list subscribers of specified type
#  */
def list_each_subs seq, subs, type, msg
  count = 0;
  subs.type = type
  subs.index = 0
  while seq.query_port_subscribers(subs)
    if (count == 0)
      printf("\t%s: ", msg);
    else
      printf(", ");
    end
    addr = subs.addr
    printf("%d:%d", addr[0], addr[1]);
    printf(", root=%d:%d" % subs.root);
    printf("[ex]") if subs.exclusive?
    if subs.time_update?
      printf("[%s:%d]",
             subs.time_real? ? "real" : "tick",
             subs.queue)
    end
    subs.index += 1
    count += 1
  end
  print "\n" if (count > 0)
end

# /*
#  * list subscribers
#  */
def list_subscribers(seq, addr)
  subs = query_subscribe_malloc
#   snd_seq_query_subscribe_alloca(&subs);
  subs.root = addr
  list_each_subs(seq, subs, SND_SEQ_QUERY_SUBS_READ, _("Connecting To"));
  list_each_subs(seq, subs, SND_SEQ_QUERY_SUBS_WRITE, _("Connected From"));
end

# /*
#  * search all ports
#  */
# typedef void (*action_func_t)(snd_seq_t *seq, snd_seq_client_info_t *cinfo, snd_seq_port_info_t *pinfo, int count);

def do_search_port(seq, perm, &do_action)
#   snd_seq_client_info_t *cinfo;
#   snd_seq_port_info_t *pinfo;
#   int count;

  cinfo = client_info_malloc
  pinfo = port_info_malloc
  cinfo.client = -1
  while (seq.query_next_client(cinfo))
#     /* reset query info */
    pinfo.client = cinfo.client
    pinfo.port = -1
    count = 0
    while (seq.query_next_port(pinfo))
      if (check_permission(pinfo, perm))
        do_action.call(seq, cinfo, pinfo, count);
        count += 1
      end
    end
  end
end

# callbacks, C style!
def print_port(seq, cinfo, pinfo, count)
  if (count == 0)
    printf(_("client %d: '%s' [type=%s]\n"),
           cinfo.client, cinfo.name, cinfo.type == SND_SEQ_USER_CLIENT ? _("user") : _("kernel"));
  end
  printf("  %3d '%-16s'\n", pinfo.port, pinfo.name)
end

def print_port_and_subs(seq, cinfo, pinfo, count)
  print_port(seq, cinfo, pinfo, count);
  list_subscribers(seq, pinfo.addr)
end


# /*
#  * remove all (exported) connections
#  */
def remove_connection(seq, cinfo, pinfo, count)

  query = query_subscribe_malloc
#   snd_seq_query_subscribe_alloca(&query);
  query.root = pinfo.addr
  query.type = SND_SEQ_QUERY_SUBS_READ
  query.index = 0
  while seq.query_port_subscribers(query)
#           snd_seq_port_info_t *port;
#           snd_seq_port_subscribe_t *subs;
    sender = query.root
    dest = query.addr
    begin
      port = seq.any_port_info(dest[0], dest[1])
      if (port.capability & SND_SEQ_PORT_CAP_SUBS_WRITE) != 0 &&
          (port.capability & SND_SEQ_PORT_CAP_NO_EXPORT) == 0
        subs = port_subscribe_malloc
        subs.queueu = query.queue
        sub.sender = sender
        sub.dest = dest
        seq.unsubscribe_port(subs);
      end
    rescue AlsaMidiError=>e
      STDERR.puts "WARNING: #{e}"
    end
    query.index += 1
  end

  query.type = SND_SEQ_QUERY_SUBS_WRITE
  query.index = 0
  while seq.query_port_subscribers(query)
    dest = query.root
    sender = query.addr
    begin
      port = seq.any_port_info(sender[0], sender[1])
      if (port.capability & SND_SEQ_PORT_CAP_SUBS_READ) != 0 &&
         (port.capability & SND_SEQ_PORT_CAP_NO_EXPORT) == 0
        subs = port_subscribe_malloc
        subs.queue = query.queue
        subs.sender = sender
        subs.dest = dest
        seq.unsubscribe_port(subs);
      end
    rescue AlsaMidiError=>e
      STDERR.puts "WARNING: #{e}"
    end
    query.index += 1
  end
end

def remove_all_connections(seq)
  do_search_port(seq, 0) { |seq2, c, p, count| remove_connection(seq2, c, p, count) }
end


# /*
#  * main..
#  */

SUBSCRIBE = 0
UNSUBSCRIBE = 1
LIST = 2
REMOVE_ALL = 3
$PROGRAM_NAME = 'rconnect'

#         int c;
#         snd_seq_t *seq;
queue = 0
convert_time = convert_real = exclusive = false

command = SUBSCRIBE;
list_perm = 0
#         int client;
list_subs = false
#         snd_seq_port_subscribe_t *subs;
#         snd_seq_addr_t sender, dest;

#         setlocale(LC_ALL, "");
#         textdomain(PACKAGE);

require 'optparse'
opts = OptionParser.new
opts.banner = "Usage: #$PROGRAM_NAME [options] [sender] [receiver]"
opts.on('-h', '--help', 'this help') { usage; exit 1; }
opts.on('-d', '--disconnect', 'disconnect sender from receiver') { command = UNSUBSCRIBE }
opts.on('-i', '--input', 'list input ports') { command = LIST; list_perm |= LIST_INPUT }
opts.on('-o', '--output', 'list output ports') { command = LIST; list_perm |= LIST_OUTPUT }
opts.on('-l', '--list', 'list correct connections (use with -i/-o)') { list_subs = true }
opts.on('-r', '--real=QUEUE', 'convert realtime timestamps', Integer) { |q| queue = q; convert_time = convert_real = true }
opts.on('-t', '--tick=QUEUE', 'convert tick timestamps', Integer) { |q| queue = q; convert_time = true; convert_real = false }
opts.on('-e', '--exclusive', 'make an exclusive connection') { exclusive = true }
opts.on('-x', '--removeall', 'remove all exported connections') { command = REMOVE_ALL }

sender_receiver = opts.parse ARGV

seq = seq_open("default", SND_SEQ_OPEN_DUPLEX, 0)

snd_lib_error_set_handler do |file, line, function, err, text|
  STDERR.puts "error CALLBACK triggered!!"
  if (err != Errno::ENOENT::Errno)      # Ignore those misleading "warnings"
    s = "ALSA lib %s:%i:(%s) " %  [file, line, function]
    s += text
    s += ": %s" % snd_strerror(err) if err != 0
    s += "\n"
    raise AlsaMidiError, s
  end
end

case command
when LIST
  do_search_port(seq, list_perm) do |l_seq, cinfo, pinfo, count|
    if list_subs then print_port_and_subs(l_seq, cinfo, pinfo, count)
    else print_port(l_seq, cinfo, pinfo, count)
    end
  end
  seq.close
  exit 0
when REMOVE_ALL
  remove_all_connections(seq);
  seq.close
  exit 0
end

#         /* connection or disconnection */

if sender_receiver.length != 2
  seq.close
  usage
  exit(1);
end

client = seq.client_id
# /* set client info */
seq.client_name = "ALSA Connector"

# /* set subscription */
sender = seq.parse_address(sender_receiver[0])
dest = seq.parse_address(sender_receiver[1])
subs = port_subscribe_malloc
subs.sender = sender
subs.dest = dest
subs.queue = queue
subs.exclusive = exclusive
subs.time_update = convert_time
subs.time_real = convert_real

if (command == UNSUBSCRIBE)
  seq.unsubscribe_port(subs) if seq.get_port_subscription(subs)
else
  if seq.port_subscription?(subs)
    seq.close
    SRDERR.printf(_("Connection is already subscribed\n"));
    exit 1;
  end
  seq.subscribe_port subs
end

seq.close

