
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../model'

=begin rdoc

This class is strongly tied to the Qt::CalendarWidget (called CW here).

There is also a problem with priorities and functionality (and responsibilities?)

priorities: minimumDate can be set by the user, and should then alter CW.minimumDate.
However, initially the models minimumDate should be CW.minimumDate. So, when we
connect the model to the CW, should minimumDate set model.mindate or should model.mindate
be stored in CW?

functionality: the PossibleVerticalHeaderOptions and similar constants are actually
part of the model, but already defined in CW. Better put, there values are stored,
but the value group is defined nowhere explicitely!

naming issues: CW uses 'selectedDate' which is 'today' by default but it is unrelated
to it. If we initialize @selectedDate to 'today' and we pass the 00:00 time boundary
we lag a day, and that becomes worse.  But if we force selectedDate on the current date
we bypass userinput.
What do I want:
  - when the model connects, using 'initialize' then the default picked should be the
    current date, according to Time.now.

responsibility:
  - the model can set a default. Should this work for each run of the form? Or should
  the last set value retain?
  - the program can set a default.

The current date may change.
SOLUTIONS
=========
1) we can steal the initial mindate and maxdate.
2) we can initially set them to nil. Then when connecting to the CW we copy them out.
But... this is contrary to what connectModel should do. And if the mindate edit is visited
before the CW, it would remain unset!
3) we can create a dummy CW and steal its mindate and maxdate (not to mention currentdate).
4) screw Qt, and lets invent a proper mindate, maxdate and curdate.
   For example Jan 2 -4713  and  Dec 31 7999
   This is actually the same as solution 1)

=end
  class CalendarModel < Qt::Object # QObject required for 'tr'
    include Model

    # based on first three letters of locale converted monthnames.
    private
    def initialize parent, qtc
      super()
      @minimumDate = CalendarModel::to_date 'Sep', 14, 1752 # start of modern calendar
          # (in the US!!!! the rest of the world had it two centuries sooner)
      @maximumDate = CalendarModel::to_date 'Dec', 31, 2999
      @selectionMode = Qt::CalendarWidget::SingleSelection
      @horizontalHeaderFormat = Qt::CalendarWidget::ShortDayNames
      @verticalHeaderFormat = Qt::CalendarWidget::ISOWeekNumbers
      @navigationBarVisible = true
      @gridVisible = false
      @firstDayOfWeek = Qt::Sunday
      @selectedDate = nil # Qt::Date.new (dangerous, let's say 'nil' represent Qt.Date.new)
      @locale = ENV['LANG'].sub(/\..*/, '') || 'C'
#       @selectedDate = CalendarModel::to_date
=begin HOLES
 1) locale
 2) colors
 3) headerformat
=end
    end

    def self.calcmonth str
      str = str.upcase
      for m in (1..12)
        Qt::Date::shortMonthName(m).upcase == str and return m
      end
      for m in (1..12)
        Qt::Date::longMonthName(m).upcase == str and return m
      end
      raise ArgumentError, tr('Unable to parse monthname') + " '#{str}'"
    end

    public

    dynamic_accessor :minimumDate, :maximumDate, :selectionMode,
                     :horizontalHeaderFormat, :verticalHeaderFormat,
                     :firstDayOfWeek, :selectedDate, :locale

    dynamic_bool :navigationBarVisible, :gridVisible

=begin rdoc
    convert arguments to a Qt::Date (not a ruby Time)
    Possibly understood arguments:
      dd-mm-yy(yy)? or yyyy.mm.dd or mm[^-]dd[^-]yy(yy)?
      dd.MMM.yy(yy)? or MMM.dd.yy(yy)?
      yy(yy)?.MMM.dd
      split in three triple integers y m d
      int/string triples dMy yMd Mdy as long y > 31

    This method raises ArgumentError on any bad arguments or invalid date
    results.

    Any month string must match the Qt shortname for that month, in the active
    locale. I assume they are always 3 long.
    However if the string does not match any shortname then it will be matched with the longname
    automatically. This match is case insensitive.
    So 1-1-10 is understood, so is, '2010 Februari 2'
=end
    def self.to_date *arg
#       tag "to_date #{arg.inspect}"
      l = arg.length
      raise ArgumentError, tr("invalid date") + " '#{arg.inspect}'" if l != 1 && l != 3
      if l == 1
        case date = arg[0].to_str
        when /(\d{1,2})-(\d{1,2})-(\d\d(\d\d)?)/
#           tag "continental, $1=#$1, $2=#$2,$3=#$3"
          d, m, y = $1, $2, $3
#           tag "dmy= #{d}, #{m}, #{y}"
        when /(?<month>\d{1,2})(?<sep>\W)(?<day>\d{1,2})\k<sep>(?<year>\d\d(\d\d)?)/
#           tag "american, '#{$1}' '#{$2}' '#{$3}' '#{$4}' '#{$5}'"
#           tag "MATCHDATA: #{$~.inspect}"
          d, m, y = $~[:day], $~[:month], $~[:year]
        when /(?<year>\d{4})(?<sep>\W)(?<month>\d{1,2})\k<sep>(?<day>\d{1,2})/
#           tag "sortable"
          d, m, y = $4, $3, $1
        when /(?<day>\d{1,2})(?<sep>\W)(?<month>\p{Alpha}{3,})\k<sep>(?<year>\d\d(\d\d)?)/
#           tag "continental, monthname"
          d, m, y = $1, calcmonth($3), $4
        when /(?<month>\p{Alpha}{3,})(?<sep>\W)(?<day>\d{1,2})\k<sep>(?<year>\d\d(\d\d)?)/
#           tag "american, monthname"
          d, m, y = $3, calcmonth($1), $4
        when /(?<year>\d\d(\d\d)?)(?<sep>\W)(?<month>\p{Alpha}{3,})\k<sep>(?<day>\d{1,2})/
#           tag "standard, monthname, Match=#{$~.inspect}"
          d, m, y = $~[:day], calcmonth($~[:month]), $~[:year]
        else
          raise ArgumentError, tr("invalid date") + " '#{date}'"
        end
      else # 3 integers then
        y, m, d = arg
#         tag "y,m,d=#{y},#{m},#{d}"
        # unless...
        if y.respond_to?(:to_str)
          m, d, y = calcmonth(y.to_str), m, d
        elsif m.respond_to?(:to_str)
          if y > 31
            m = calcmonth(m)
          else
            d, m, y = y, calcmonth(m), d
          end
        end
      end
      d, m, y = d.to_i, m.to_i, y.to_i
#       tag "m = #{m}, d = #{d}, y = #{y}"
      raise ArgumentError, tr("invalid month") + " '#{m}'" unless (1..12) === m
      raise ArgumentError, tr("invalid day") + " '#{d}'" unless (1..31) === d
      # these should be shifted as the years pass, but I'm a bit lazy
      y = y < 60 ? 2000 + y : 1900 + y if y < 100
#       Time.local(y, m, d)
      Qt::Date.new(y, m, d).tap do |dat|
        unless dat.valid?
          raise ArgumentError, tr("invalid date") + (" '%02d-%02d-%04d'" % [d,m,y])
        end
      end
    end # def to_date

    # translated days of the week where 0 is Sunday
    WeekDaysFromSun2Sat = {
                       Qt::Sunday=>tr('Sunday'), Qt::Monday=>tr('Monday'),
                       Qt::Tuesday=>tr('Tuesday'), Qt::Wednesday=>tr('Wednesday'),
                       Qt::Thursday=>tr('Thursday'), Qt::Friday=>tr('Friday'),
                       Qt::Saturday=>tr('Saturday') }

  end # class CalendarModel

  createInstantiator File.basename(__FILE__, '.rb'), nil, CalendarModel

end
