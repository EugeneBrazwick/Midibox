CREATE SCHEMA tagdb;
SET search_path TO tagdb, public;

--   tag is the base class. It is just a name.
--   We extend it to:
--       deviceclass - a specific device type like 'Roland E-80'
--       device - a specific device in YOUR configuration, like 'my E-80'
--       program - a specific program on a specific device, including a midi activator
--       voice - a logical 'program'. If a program is created with a name not in voices,
--           the voice is added with the program as default connection.
--       part - a construction of voices. May be more than one channel, more than one device.
--       section - like piano, percussion, effects, pads, strings, brass, woods etc..
--       instrument - a class of musical instrumets
--       rhythm - boogie, waltz
--       styleclass - ballroom, rock, jazz
--       musicspeed - adagio, allegro
--       musicalfeeling - sad, happy, grave
--       style - specific style, like 'Stevie Wonder Ballad'.
--
CREATE TABLE tags(
   id SERIAL NOT NULL PRIMARY KEY,
   name VARCHAR NOT NULL,
   description TEXT
);

-- a connection ties two tags together
CREATE TABLE connections
(
  reffingtag_id INTEGER NOT NULL REFERENCES tags,
  -- the next one also references 'tags'
  reffedtag_id INTEGER NOT NULL REFERENCES tags,
  weight FLOAT DEFAULT 1.0 NOT NULL,
  PRIMARY KEY (reffingtag_id, reffedtag_id)
);

-- a deviceclass is a specific model of some device
CREATE TABLE deviceclasses
(
  tag_id INTEGER NOT NULL PRIMARY KEY REFERENCES tags
);

-- a device is one of 'your' specific devices
CREATE TABLE devices
(
  tag_id INTEGER NOT NULL PRIMARY KEY REFERENCES tags,
  deviceclass_id INTEGER NOT NULL REFERENCES deviceclasses
);

-- a program is a midibytesequence to accomplish a programswitch.
-- not just a literal programchangecontrol sequence.
-- it may contain device specific settings as well.
CREATE TABLE programs
(
  tag_id INTEGER NOT NULL PRIMARY KEY REFERENCES tags,
  deviceclass_id INTEGER NOT NULL REFERENCES deviceclasses,
  actuator BYTEA NOT NULL
);


