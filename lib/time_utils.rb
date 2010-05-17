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

    def self.parse(text, format)
      begin
        res = DateTime.strptime(text, format)
      rescue ArgumentError
        res = nil
      end
      res
    end

    def self.format(text, format)
      DateTime.strptime(text, format)
    end

    attr_accessor :date_format
    attr_accessor :time_format

    def initialize(date_format, time_format)
      @date_format = date_format
      @time_format = time_format
    end

    def valid_date?(text)
      DateTimeConverter.valid?(text, @date_format)
    end

    def valid_time?(text)
      DateTimeConverter.valid?(text, @time_format)
    end

    def valid_datetime?(text)
      DateTimeConverter.valid?(text, datetime_format)
    end

    def datetime_format
      "#{@date_format} #{@time_format}"
    end

  end

  class DurationConverter

    #/^\s*((\d+)w)?\s*((\d+)d)?\s*((\d+)h)?\s*((\d+)m)?\s*$/,
    FORMAT_REGEXES = [
      Regexp.new("\\s((\\s+)#{i18n.t(:w)})?\\s*((\\d+)#{i18n.t(:d)})?\\s*((\\d+)#{i18n.t(:h)})?\\s*((\\d+)#{i18n.t(:m)})?\\s*$"),
      Regexp.new("\\s((\\s+)#{i18n.t(:w)})?\\s*((\\d+)#{i18n.t(:d)})?\\s*((\\d+)#{i18n.t(:h)})?\\s*((\\d+)#{i18n.t(:m)})?\\s*$"),
      /((\d+):)?((\d+):)?((\d+):)?(\d{2})/,
      /((\d+):)?(\d{2})/,
      #/\d+:\d{2}/,
      /\d+\.\d{2}/
    ]

    attr_accessor :format
    attr_accessor :days_per_week
    attr_accessor :workday_duration

    def self.index_to_regex(index)
      index.is_a?(FixNum) ? FORMAT_REGEXES[index] : index
    end

    def self.valid?(text, format)
      text =~ DurationConverter.index_to_regex(format)
    end

    def self.duration_hash(secs, workday_duration, days_per_week)
      d = {}
      d[:weeks] = secs / (workday_duration * days_per_week)
      secs %= workday_duration * days_per_week 
      d[:days] = secs / minsPerDay
      secs %= workday_duration
      d[:hours] = secs / 60 / 60
      secs %= 60 * 60
      d[:minutes] = secs / 60
      d[:seconds ] secs % 60
      return d
    end

    def format(orig_seconds, duration_format, day_duration, days_per_week = 5)
      res = ''
      weeks = days = hours = 0

      day_duration ||= 480
      orig_minutes ||= 0
      minutes = orig_seconds / 60

      case duration_format
      when 0, 1
        #Worded
        if minutes >= 60

          days = minutes / day_duration
          minutes = minutes - (days * day_duration) if days > 0

          weeks = days / days_per_week
          days = days - (weeks * days_per_week) if weeks > 0

          hours = minutes / 60
          minutes = minutes - (hours * 60) if hours > 0

          res += "#{weeks}#{I18n.t(:w)}#{' ' if duration_format == 0}" if weeks > 0
          res += "#{days}#{I18n.t(:d)}#{' ' if duration_format == 0}" if days > 0
          res += "#{hours}#{I18n.t(:h)}#{' ' if duration_format == 0}" if hours > 0
        end
        res += "#{minutes}#{I18n.t(:m)}" if minutes > 0 || res == ''
      when 2
        #columned
        res = if weeks > 0
                format("%d:%d:%d:%02d", weeks, days, hours, minutes)
              elsif days > 0
                format("%d:%d:%02d", days, hours, minutes)
              else
                format("%d:%02d", hours, minutes)
              end
      when 3
        #hours:minutes
        res = format("%d:%02d", orig_seconds / 3600, orig_seconds % 3600)
      when 4
        #decimal
        res = format("%.2f", orig_seconds/3600.0)
      end

      res.strip
    end

    def self.parse(text, format)
      res = nil
      case format
      when 0, 1 then 
        res = DurationConverter.parse_worded_localized(text)
      when 2, 3 then
        res = DurationConverter.parse_columned(text)
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
          when I18n.t(:h) then total += e.to_i * 60
          when I18n.t(:m) then total += e.to_i
          end
        end
      end

      return total
    end

    def self.parse_worded(text, workday_duration, days_per_week)
      total = 0
      reg = /([wdhm])/

      text.strip.downcase.gsub(/ {2,}/, ' ').gsub(reg,'\1 ').split(' ').each do |e|
        part = /(\d+)(\w+)/.match(e)
        if part && part.size == 3
          case  part[2]
          when 'w' then total += e.to_i * workday_duration * days_per_week
          when 'd' then total += e.to_i * workday_duration
          when 'h' then total += e.to_i * 60
          when 'm' then total += e.to_i
          end
        end
      end

      return total
    end

    def self.parse_columned(text, workday_duration, days_per_week)
      return nil unless DateTimeConverter.valid?(text, 1)
      times = text.strip.split(':')
      while time = times.shift
        case times.length
        when 0 then total += time.to_i
        when 1 then total += time.to_i * 60
        when 2 then total += time.to_i * workday_duration
        when 3 then total += time.to_i * workday_duration * days_per_week
        end
      end
    end

    def self.parse_decimaled(text)
      return nil unless DateTimeConverter.valid?(text, 2)
      total = (input.strip.to_f * 60).round
    end


    def self.duration(start, stop, format)
      date_start = DateTimeConverter.parse(start, format)
      date_stop = DateTimeConverter.parse(stop, format)
      return nil if date_start.nil? or date_stop.nil?
      date_start - date_stop
    end

    def initialize(duration_format, workday_duration, days_per_week, datetime_converter)
      @duraton_format = DurationConverter.index_to_regex(format)
      @datetime_converter = datetime_converter
      @workday_duration = workday_duration
      @days_per_week = days_per_week
    end

    def duration(start, stop)
      DurationConverter.duration(start, stop, @datetime_converter.datetime_format)
    end

    def parse(text)
      DurationConverter.parse(text, @duration_format)
    end

    def format(seconds)
      DurationConverter.format(seconds, @duration_format, @workday_duration, @days_per_week)
    end

  end

end
