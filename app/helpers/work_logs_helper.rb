module WorkLogsHelper
  ###
  # Returns a hash to use as the options for the task
  # status dropdown on the work log edit page.
  ###
  def work_log_status_html_options
    options = {}
    options[:disabled] = "disabled" unless current_user.can?( @task.project, "close" )

    return options
  end

  # Returns a list of customers/clients that could a log
  # could potentially be attached to
  def work_log_customer_options(log)
    res = @log.task.customers.clone
    res << @log.task.project.customer

    res = res.uniq.compact
    return objects_to_names_and_ids(res)
  end

  ###
  # Returns an array to use as the options for a select
  # to change a work log's status.
  ###
  def work_log_status_options
    options = []
    options << [_("Leave Open"), 0] if @task.status == 0
    options << [_("Revert to Open"), 0] if @task.status != 0
    options << [_("Close"), 2] if @task.status > 0
    options << [_("Leave Closed"), 2] if @task.status == 1
    options << [_("Set as Won't Fix"), 3] if @task.status == 0
    options << [_("Leave as Won't Fix"), 3] if @task.status == 2
    options << [_("Set as Invalid"), 4] if @task.status == 0
    options << [_("Leave as Invalid"), 4] if @task.status == 3
    options << [_("Set as Duplicate"), 5] if @task.status == 0
    options << [_("Leave as Duplicate"), 5] if @task.status == 4

    return options
  end
end
