=begin rdoc

module RStore makes a persistent object
out of any ruby object, with recursion and all.

Features - transactions
         - two phase commit
         - yaml

Not implemented: - security

=end

module RStore

  MainStorageDir = '/var/lib/RStore'
  AltStorageDir = ENV['HOME'] + '/.rstore'
  @@storage_dir = MainStorageDir
end