###
# Helpers for displaying dates and times
###
module DateAndTimeHelper

  ###
  # Returns a string of the given date time formatted according to 
  # the current user's preferences
  ###
  def formatted_datetime_for_current_user(datetime)
    datetime.strftime("#{ current_user.date_format } #{ current_user.time_format }") if datetime
  end

  ###
  # Parses the date string at params[key_name] according to the 
  # current user's prefs. If no date is found, the current
  # date is returned.
  # The returned data will always be in UTC.
  ###
  def date_from_params(params, key_name)
    res = Time.now.utc

    begin
      str = params[key_name]
      format = "#{current_user.date_format} #{current_user.time_format}"
      date = DateTime.strptime(str, format)
      res = tc.local_to_utc(date) if date
    rescue
      # just fall back to default if error
    end

    return res
  end

end
