
require_relative '../alsa_midi'

include RRTS::Driver
seq = seq_open
seq.query_named_queue('Err');
