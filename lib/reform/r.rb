module R

  public # methods of R
  ## use this to wrap a rescue clause around any block.
  # transforms the exception (RuntimeError+IOError+StandardError) to a warning on stderr.
  # Reform::Error is also a RuntimeError.
  #
  # UNLESS: 'fail_on_errors true' is specified in Application.
    def self.escue
      begin
        return yield
      rescue IOError => exception
	raise if $app.fail_on_errors?
        msg = "#{exception.message}\n"
      rescue StandardError, RuntimeError => exception
	raise if $app.fail_on_errors?
	#tag "got exception"
	#tag "exception class: #{exception.class}"
	#tag "exception msg: #{exception}"
	#tag "exception backtrace: #{exception.backtrace.join "\n"}"
        msg = "#{exception.class}: #{exception}\n" + exception.backtrace.join("\n")
      end
      $stderr << msg
      nil
    end # escue

  module EForm 
      class Error < RuntimeError; end
  end
end # module R

Reform = R::EForm


