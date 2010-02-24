#!/usr/bin/ruby1.9.1
# $Id: patchrecorder.rb,v 1.1 2010/02/17 23:07:37 ara Exp ara $

module RTTS

class PatchRecorder
private
# connect to alsa and record from given port.

  def initialize alsaportname, timeout = 5, moreparams = nil
  end

public
# convenience method
  def self.list_alsaportnames
    require_relative 'alsa/alsa'
    seq = Alsa.sequencer.new
  end
end # class PatchRecorder

end # RTTS