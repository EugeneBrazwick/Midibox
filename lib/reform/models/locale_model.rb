
# Copyright (c) 2010 Eugene Brazwick

require_relative '../model'

module Reform

  class LocaleModel < AbstractModel # < Qt::Object # QObject required for 'tr'
    include Enumerable

    private
    def initialize
      super
      @locales = nil
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
      unless @locales
        @locales = {}
        l = Qt::Locale::C
        while l <= Qt::Locale::LastLanguage
          @locales[Qt::Locale.new(l).name] = true
          l += 1
        end
#         @locales.sort!
      end
      # delegate!
      @locales.keys.each(&block)
#       each_pair { |locale, text| yield [locale, text] }
    end
  end # class LocaleModel

  createInstantiator File.basename(__FILE__, '.rb'), nil, LocaleModel

end # module Reform