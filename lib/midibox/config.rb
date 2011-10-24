
require 'forwardable'

module Midibox
  class Config 
    extend Forwardable
    private
      def initialize *args
        super
        @last_song = nil # 'default' is dangerous because not really the name to be saved
#         tag "creating filesystem for song"
        @songfile = filesystem {
          dirname Dir::home + '/.midibox'
          default_filename 'default.mdb.yaml.gz'
          if !File.exists?(fnam = dirname + '/' + default_filename)
            # copy stock version to userdir first.
            # Currently no such file exists.
            File.open(fnam, 'w') { |f| }
          end
          filename nil
          itemname $qApp.tr('Midibox Song')
          pattern '*.mdb.yaml.gz *.mdb.yaml'
        }
      end

    public
      def fileNew
        @songfile.open_file
        @last_song = nil
      end

      def fileOpen sender
        @songfile.open sender
        self.last_song = songfile.path
      end

      def fileSave sender
        songfile.save sender
        self.last_song = songfile.path
      end

      def fileSaveAs sender
        songfile.save_as sender
        self.last_song = songfile.path
      end

      def_delegators :songfile, :save_caption, :saveas_caption, :new_caption, :open_caption
  end
end
