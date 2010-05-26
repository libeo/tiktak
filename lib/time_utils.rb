module TimeUtils

  class DateTimeConverter

    def self.valid?(text, format)
      valid = true
      begin
        DateTime.strptime(text, format)
      rescue ArgumentError
        valid = false
      end
      valid
    end

    def self.parse_date(text, format)
      begin
        res = Date.strptime(text, format)
      rescue ArgumentError
        res = nil
      end
      res
    end

    def self.parse_datetime(text, format, timezone=nil)
      begin
        res = DateTime.strptime(text, format)
        res = timezone.local_to_utc(res) if timezone
      rescue ArgumentError
        res = nil
      end
      res
    end

    def self.format(datetime, format)
      datetime.strftime(datetime, format)
    end

    attr_accessor :date_format
    attr_accessor :time_format
    attr_accessor :time_zone

    def initialize(date_format, time_format, time_zone)
      @date_format = date_format
      @time_format = time_format
      @time_zone = time_zone
    end

    def valid_date?(text)
      DateTimeConverter.valid?(text, @date_format)
    end

    def valid_datetime?(text)
      DateTimeConverter.valid?(text, datetime_format)
    end

    def format_date(date)
      DateTimeConverter.format_date(date, @date_format)
    end

    def format_datetime(datetime)
      DateTimeConverter.format(datetime, datetime_format)
    end

    def parse_date(text)
      DateTimeConverter.parse_date(text, @date_format)
    end

    def parse_datetime(text)
      DateTimeConverter.parse_datetime(text, datetime_format, @time_zone)
    end

    def parse_time(text)
      DateTimeConverter.parse_datetime(text, @time_format, @time_zone).to_time
    end

    def datetime_format
      "#{@date_format} #{@time_format}"
    end

  end

  class DurationConverter

    #/^\s*((\d+)w)?\s*((\d+)d)?\s*((\d+)h)?\s*((\d+)m)?\s*$/,
    FORMAT_REGEXES = [
      Regexp.new("\\s((\\s+)#{I18n.t(:w)})?\\s*((\\d+)#{I18n.t(:d)})?\\s*((\\d+)#{I18n.t(:h)})?\\s*((\\d+)#{I18n.t(:m)})?\\s*$"),
      Regexp.new("\\s((\\s+)w)?\\s*((\\d+)d)?\\s*((\\d+)h)?\\s*((\\d+)m)?\\s*$"),
      /((\d+):)?((\d+):)?((\d+):)?(\d{2})/,
      /((\d+):)?(\d{2})/,
      #/\d+:\d{2}/,
      /\d+\.\d{2}/
    ]

    attr_accessor :duration_format
    attr_accessor :days_per_week
    attr_accessor :workday_duration

    def self.index_to_regex(index)
      index.is_a?(Fixnum) ? FORMAT_REGEXES[index] : index
    end

    def self.valid?(text, format)
      !(text =~ DurationConverter.index_to_regex(format)).nil?
    end

    def self.duration_hash(secs, workday_duration, days_per_week)
      d = {}
      d[:weeks] = secs / (workday_duration * days_per_week)
      secs %= workday_duration * days_per_week
      d[:days] = secs / workday_duration
      secs %= workday_duration
      d[:hours] = secs / 60 / 60
      secs %= 60 * 60
      d[:minutes] = secs / 60
      d[:seconds] = secs % 60
      return d
    end

    def self.format(seconds, duration_format, day_duration, days_per_week = 5)
      seconds = seconds.to_i
      res = ''
      weeks = days = hours = minutes = 0

      case duration_format
      when 0, 1, 2
    
        weeks = seconds / (day_duration * days_per_week)
        seconds %= (day_duration * days_per_week)

        days = seconds / day_duration
        seconds %= day_duration

        hours = seconds / 3600
        seconds %= 3600

        minutes = seconds / 60
        seconds %= 60

        cap = []
        cap << "#{weeks}#{I18n.t(:w)}" if weeks > 0
        cap << "#{days}#{I18n.t(:d)}" if days > 0
        cap << "#{hours}#{I18n.t(:h)}" if hours > 0
        cap << "#{minutes}#{I18n.t(:m)}" if minutes > 0 or cap.length == 0

        case duration_format
        when 0
          res = cap.join ' '
        when 1
          res = cap.join ''
        when 2
          res = cap.join ':'
        end

      when 3
        #hours:minutes
        hours = seconds / 3600
        minutes = (seconds % 3600) / 60
        res = Kernel.format("%d:%02d", hours, minutes)
      when 4
        #decimal
        res = Kernel.format("%.2f", seconds/3600.0)
      end

      res.strip
    end

    def self.parse(text, format, workday_duration, days_per_week)
      res = nil
      case format
      when 0, 1 then 
        res = DurationConverter.parse_worded_localized(text, workday_duration, days_per_week)
      when 2, 3 then
        res = DurationConverter.parse_columned(text, workday_duration, days_per_week)
      when 4 then
        res = DurationConverter.parse_decimaled(text)
      end
      res = DurationConverter.parse_worded(text) if res.nil? and [0,1].include?(format)

      return res
    end

    def self.parse_worded_localized(text, workday_duration, days_per_week)
      return nil unless DurationConverter.valid?(text, 0)
      total = 0
      reg = Regexp.new("([#{I18n.t(:w)}#{I18n.t(:d)}#{I18n.t(:h)}#{I18n.t(:m)}])")
      #reg = /([wdhm])/

      text.strip.downcase.gsub(/ {2,}/, ' ').gsub(reg,'\1 ').split(' ').each do |e|
        part = /(\d+)(\w+)/.match(e)
        if part && part.size == 3
          case  part[2]
          when I18n.t(:w) then total += e.to_i * workday_duration * days_per_week
          when I18n.t(:d) then total += e.to_i * workday_duration
          when I18n.t(:h) then total += e.to_i * 60 * 60
          when I18n.t(:m) then total += e.to_i * 60
          end
        end
      end

      return total
    end

    def self.parse_worded(text, workday_duration, days_per_week)
      return nil unless DurationConverter.valid?(text, 1)
      total = 0
      reg = /([wdhm])/

      text.strip.downcase.gsub(/ {2,}/, ' ').gsub(reg,'\1 ').split(' ').each do |e|
        part = /(\d+)(\w+)/.match(e)
        if part && part.size == 3
          case  part[2]
          when 'w' then total += e.to_i * workday_duration * days_per_week
          when 'd' then total += e.to_i * workday_duration
          when 'h' then total += e.to_i * 60 * 60
          when 'm' then total += e.to_i * 60
          end
        end
      end

      return total
    end

    def self.parse_columned(text, workday_duration, days_per_week)
      return nil unless DurationConverter.valid?(text, 2)
      times = text.strip.split(':')
      total = 0
      while time = times.shift
        case times.length
        when 0 then total += time.to_i * 60
        when 1 then total += time.to_i * 60 * 60
        when 2 then total += time.to_i * workday_duration
        when 3 then total += time.to_i * workday_duration * days_per_week
        end
      end
      return total
    end

    def self.parse_decimaled(text)
      return nil unless DurationConverter.valid?(text, 4)
      total = (input.strip.to_f * 60).round * 60
    end


    def self.duration(start, stop, format)
      date_start = DateTimeConverter.parse_datetime(start, format)
      date_stop = DateTimeConverter.parse_datetime(stop, format)
      return nil if date_start.nil? or date_stop.nil?
      date_start - date_stop
    end

    def initialize(duration_format, workday_duration, days_per_week, datetime_converter)
      @duration_format = duration_format
      @datetime_converter = datetime_converter
      @workday_duration = workday_duration
      @days_per_week = days_per_week
    end

    def duration(start, stop)
      DurationConverter.duration(start, stop, @datetime_converter.datetime_format)
    end

    def parse(text)
      DurationConverter.parse(text, @duration_format, @workday_duration, @days_per_week)
    end

    def format(seconds)
      DurationConverter.format(seconds, @duration_format, @workday_duration, @days_per_week)
    end

    def valid?(text)
      DurationConverter.valid?(text, @duration_format)
    end

  end

end
