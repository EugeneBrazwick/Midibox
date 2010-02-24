# use: swig -c++ -ruby -autorename rjack.swig && make
# $Id: rjack.swig,v 1.2 2009/06/25 19:54:38 ara Exp ara $

%module rjack

# make sure the generated c file can access jack.h:
%{
#include "rjack.h"
%}

%include "typemaps.i"
%include "std_string.i"
%include "std_vector.i"

using namespace std;

#define JACK_DEFAULT_AUDIO_TYPE "32 bit float mono audio"
#define JACK_DEFAULT_MIDI_TYPE "8 bit raw midi"

enum JackPortFlags {
     JackPortIsInput = 0x1,
     JackPortIsOutput = 0x2,
     JackPortIsPhysical = 0x4,
     JackPortCanMonitor = 0x8,
     JackPortIsTerminal = 0x10
};

enum JackOptions {
     JackNullOption = 0x00,
     JackNoStartServer = 0x01,
     JackUseExactName = 0x02,
     JackServerName = 0x04,
     JackLoadName = 0x08,
     JackLoadInit = 0x10
};

/** Valid options for opening an external client. */
#define JackOpenOptions (JackServerName|JackNoStartServer|JackUseExactName)

/** Valid options for loading an internal client. */
#define JackLoadOptions (JackLoadInit|JackLoadName|JackUseExactName)

%exception {
try {
$action
}
catch (const ERJack &e) {
  static VALUE cpperror = rb_define_class("JackError", rb_eStandardError);
  rb_raise(cpperror, e.msg());
}
}

jack_client_t *jack_client_open(const char *client_name, int options = 0, const char *server = 0);

int jack_client_close(jack_client_t *client);

namespace std {
  %template(Vectors) vector<string>;
};

vector<string> jack_get_ports(jack_client_t *client);
