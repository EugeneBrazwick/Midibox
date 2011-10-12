
# Copyright (c) 2010-2011 Eugene Brazwick

require 'reform/model'

module Reform

  class LocaleModel < AbstractModel # < Qt::Object # QObject required for 'tr'
    include Enumerable

    private
      def initialize parent, qtc
	super
	@locales = nil
      end

      def locales
	unless @locales
	  @locales = []
	  idx = {}
	  l = Qt::Locale::C
	  while l <= Qt::Locale::LastLanguage
	    name = Qt::Locale.new(l).name
	    unless idx[name]
	      idx[name] = true
	      @locales << name
	    end
	    l += 1
	  end
          @locales.sort!
	end
	@locales
      end

    public
      # obj=>string hash, string is displayed in lists (by default at least)
      def each_pair_BROKEN
	l = Qt::Locale::C
	while l <= Qt::Locale::LastLanguage
	  desc = Qt::Locale::languageToString(l) # + '/'
  #         countries = Qt::Locale::countriesForLanguage(l)  BROKEN in kdebindings_4.4.2
  #         for country in countries
	    label = desc # + Qt::Locale::countryToString(l.country)
	    locale = Qt::Locale.new(l) # , l.country)
=begin problems
1) Walamo and English (and many more) have locale 'en_US'.
=end
	    yield locale.name, label
  #         end
	  l += 1
	end
      end

      def each &block
	locales.each(&block)
      end

      def model_row i
	locs = locales
	#tag "locs = #{locs.inspect}"		BEWARE
	locs[i] #.tap{|t| tag"model_row(#{i}) -> #{t}"}
      end

      def length
	locales.length
      end

      def model_value2index value, view
	locales.find_index(value)
      end
      
      def model_index2value numeric_idx, view
	locales[numeric_idx]
      end
  end # class LocaleModel

  createInstantiator File.basename(__FILE__, '.rb'), nil, LocaleModel

end # module Reform
