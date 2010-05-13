module SheetsHelper

  def task_label(task, truncate_length = 45)
    res = task.issue_name + ' - ' + task.project.name
    res = res[0,truncate_length] + '...' if res.length > truncate_length 
    res
  end

  def progress_label(sheet)
    res = worked_nice(sheet.duration / 60)
    if sheet.task.duration > 0
      res += "(#{worked_nice(sheet.task.worked_minutes + sheet.duration / 60)}"
      res += " / #{worked_nice(sheet.task.duration)})"
    end
    res
  end

end
