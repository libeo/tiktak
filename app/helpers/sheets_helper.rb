module SheetsHelper

  def task_label(task, truncate_length = 45)
    res = task.issue_name + ' - ' + task.project.name
    res = res[0,truncate_length] + '...' if res.length > truncate_length 
    res
  end

  def progress_label(sheet)
    res = format_duration(sheet.duration)
    if sheet.task.duration > 0
      res += "(#{format_duration(sheet.task.worked_seconds + sheet.duration)}"
      res += " / #{format_duration(sheet.task.duration)})"
    end
    res
  end

end
