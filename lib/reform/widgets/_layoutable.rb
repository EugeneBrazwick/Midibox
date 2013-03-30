
module R::Qt
  class Layout < Control
    module Able
      public # methods of Layout::Able
      # span works in GridLayout only. If called without args
      # it always returns a tuple.
      # span with 1 arg is the same as colspan.
      # +cols+ can also be :all_remaining. This does not work for rows
	def span cols = nil, rows = nil
	  if cols
	    @span = cols, rows
	    #tag "span #{cols}, #{rows}: updated span to #{@span.inspect}"
	  else
	    r = @span || [1, 1]
	    [r[0] || 1, r[1] || 1]
	  end
	end

	def colspan cols = nil
	  if cols
	    (@span ||= [])[0] = cols
	    #tag "colspan #{cols}: updated span to #{@span.inspect}"
	  else
	    (@span || [])[0] || 1
	  end
	end # colspan
	
	def rowspan rows = nil
	  if rows
	    (@span ||= [])[1] = rows
	  else
	    (@span || [])[1] || 1
	  end
	end
    end
  end
end
