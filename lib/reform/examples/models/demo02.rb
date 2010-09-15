
# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

Reform::app {
  list {
=begin
  What's a good way to set the model?
  combobox had 'model' but I cannot specify what kind of model.
  It also has it's own way of dealing with indices, and even more,
  it copies everything as separate strings into the combobox internal listview.

  And if I say 'ruby_model { ... }'
  then this would imply setting a independent root model, as for frames.

  Well, this depends on the owner.
  Where do models pop up? In anything including (verb) ModelContext.
  We can make the following rule: if it is not a form, than it is a local model.

  A second way of gaining the internal model is to apply
  'local_connector' on the global (form) model passed to it.

  A shortcut can be possible, but it must be programmed in ModelContext.
  Like 'simpledata ['hallo', 'world']'
=end
    simpledata %w[the cat wasn't at home that day]
=begin
that was almost too easy.
=end
  }
}