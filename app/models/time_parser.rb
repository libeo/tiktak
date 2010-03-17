class TimeParser


  ###
  # Parses the date string at params[key_name] according to the 
  # current user's prefs. If no date is found, the current
  # date is returned.
  # The returned data will always be in UTC.
  ###
  def self.validate_date(format, date)
    valid = true
    begin
      DateTime.strptime(date, format)
    rescue ArgumentError
      valid = false
    end
    valid
  end

  def self.datetime_from_format(date, format)
    begin
      date = DateTime.strptime(date, format)
    rescue ArgumentError
      date = nil
    end
    date
  end
  
  def self.date_from_params(user, params, key_name)
    res = Time.now.utc

    begin
      str = params[key_name]
      format = "#{user.date_format} #{user.time_format}"
      date = DateTime.strptime(str, format)
      res = user.tz.local_to_utc(date) if date
    rescue ArgumentError
      # just fall back to default if error
    end

    return res
  end

  # Parse <tt>1w 2d 3h 4m</tt> or <tt>1:2:3:4</tt> => minutes or seconds
  def self.parse_time(user, input, minutes = false)
    total = 0
    unless input.nil?
      miss = false
      reg = Regexp.new("(#{_('[wdhm]')})")
      input.downcase.gsub(reg,'\1 ').split(' ').each do |e|
        part = /(\d+)(\w+)/.match(e)
        if part && part.size == 3
          case  part[2]
          when _('w') then total += e.to_i * user.workday_duration * user.days_per_week
          when _('d') then total += e.to_i * user.workday_duration
          when _('h') then total += e.to_i * 60
          when _('m') then total += e.to_i
          else 
            miss = true
          end
        end
      end

      # Fallback to default english parsing
      if miss
        eng_total = 0
        reg = Regexp.new("([wdhm])")
        input.downcase.gsub(reg,'\1 ').split(' ').each do |e|
          part = /(\d+)(\w+)/.match(e)
          if part && part.size == 3
            case  part[2]
            when 'w' then eng_total += e.to_i * user.workday_duration * user.days_per_week
            when 'd' then eng_total += e.to_i * user.workday_duration
            when 'h' then eng_total += e.to_i * 60
            when 'm' then eng_total += e.to_i
            end
          end
        end
        
        if eng_total > total
          total = eng_total
        end
        
      end
      
      if total == 0
        if input.strip.match(/^\d+:\d{2}$/)
          times = input.split(':')
          while time = times.shift
            case times.size
            when 0 then total += time.to_i
            when 1 then total += time.to_i * 60
            when 2 then total += time.to_i * user.workday_duration
            when 3 then total += time.to_i * user.workday_duration * user.days_per_week
		    end
		  end
        elsif input.strip.match(/^\d+\.\d{2}$/)
          total += input.strip.to_f * 60
          total = total.to_i
        end
      end

      if total == 0 && input.to_i > 0
        total = input.to_i
      end

      total = total * 60 unless minutes
      
    end
    total
  end
  
end
