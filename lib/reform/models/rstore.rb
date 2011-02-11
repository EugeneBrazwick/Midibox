

# TODO: fully persistent version of structure.rb
# And automatically persistent.

=begin

  rstores cannot be initialized with data.
  A special program should do this.
  'new' will connect to the rstore and hence a completely filled instance
  is always immediately at your service.

  rstore will use yaml files on disk and some clever cutting algo to keep
  things fast.
  rstore v1 will not be transaction save.  The data may get corrupted if
  the application crashes or in all other cases where a transaction is
  partly executed.

=end