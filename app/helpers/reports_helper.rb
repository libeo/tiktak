module ReportsHelper

  def total_amount_worked(logs)
    total = 0
    for log in logs 
      total += log.duration
    end
    total
  end 

  def total_task_worked(logs, task_id)
    total = 0
    for log in logs
      if log.task.id == task_id
        total += log.duration
      end 
    end 
    total
  end

  ###
  # Returns a select tag to use to choose what to display in
  # the report. name should probably be "rows" or "columns"
  ###
  def display_select(name, default_selected)
    options = [
               [_("Tasks"), "1"],
               [_("Tags"), "2"],
               [_("Users"), "3"],
               [_("Clients"), "4"],
               [_("Projects"), "5"],
               [_("Milestones"), "6"],
               [_("Date"), "7"],
               [_("Task Status"), "8"],
               [_("Requested By"), "20"]
              ]
    current_user.company.properties.each do |p|
      options << [ p.name, p.filter_name ]
    end
    
    if params[:report] and params[:report][name.to_sym]
      selected = params[:report][name.to_sym]
    end

    return select("report", name, options, :selected => (selected || default_selected))
  end
  
  ###
  # Returns true if the advances section of the report config section
  # should be shown.
  ###
  def show_advanced?
    show = false
    if params[:report]
      filters = params[:report]
      show ||= filters[:status] != "-1"
      show ||= filters[:tags].length > 0
      
      current_user.company.properties.each do |p|
        show ||= filters[p.filter_name] != ""
      end
    end
    
    return show
  end
  
  ###
  # Returns the html to display a select tag to choose the client/customer
  # to use for reporting.
  ###
  def client_select
    options = []
    options << [ _('[Any Client]'), '0']
    options += sorted_projects.map do |p| 
      [ p.customer.name, p.customer.id ]
    end
    options.uniq!

    selected = params[:report][:client_id].to_i if params[:report]
    
    return select("report", "client_id", options, :selected => selected) 
  end

  ###
  # Returns the html to display a select tag to choose the project
  # to use for reporting.
  ###
  def project_select
    options = []
    options << [ _('[Active Projects]'), 0 ]
    options << [ _('[Any Project]'), -1 ]
    options << [ _('[Closed Projects]'), -2 ]

    selected = params[:report][:project_id] if params[:report]
    selected ||= selected_project
    selected = selected.to_i

    if params[:report] and params[:report][:client_id].to_i > 0
      customer = current_user.company.customers.find(params[:report][:client_id])
      projects = customer.projects
    end

    projects = sorted_projects(projects)
    projects.each do |p|
      options << [ "#{ p.customer.name } - #{ p.name }", p.id ]
    end
    
    return select("report", "project_id", options, :selected => selected)

   #  <% if params[:report] && params[:report][:client_id].to_i > 0 %>
#   <%= select 'report', 'project_id', [[_('[Active Projects]'), 0], [_('[Any Project]'), -1], [_('[Closed Projects]'), -2]] + 
# 		current_user.projects.find(:all, :order => 'name', :conditions => ["customer_id = ?", params[:report][:client_id]] ).collect {|c| [ "#{c.name}", c.id ] } + 
# 		current_user.completed_projects.find(:all, :order => 'name', :conditions => ["customer_id = ?", params[:report][:client_id]] ).collect {|c| [ "#{c.name} - #{_'Completed'}", c.id ] }, 
# 		:selected => ((params[:report] && params[:report][:project_id]) ? params[:report][:project_id].to_i : session[:filter_project].to_i) %><br/>
# <% else %>
#   <%= select 'report', 'project_id', [[_('[Active Projects]'), 0], [_('[Any Project]'), -1], [_('[Closed Projects]'), -2]] + 
# 		current_user.projects.find(:all, :order => 'name').collect {|c| [ "#{c.name} / #{c.customer.name == 'Internal' ? current_user.company.name : c.customer.name }", c.id ] } + 
#                 current_user.completed_projects.find(:all, :order => 'name').collect {|c| [ "#{c.name} / #{c.customer.name == 'Internal' ? current_user.company.name : c.customer.name }" + " - #{_'Completed'}", c.id ] }, 
# 	        :selected => ((params[:report] && params[:report][:project_id]) ? params[:report][:project_id].to_i : session[:filter_project].to_i) %><br/>


#   end
  end

  ###
  # Returns an array of projects sorted by name. Active projects will be 
  # listed first (in name order), then completed projects listed next (in
  # name order there too). 
  # Pass in an array of projects to only sort those projects. Otherwise
  # all projects for the current_user will be returned.
  ###
  def sorted_projects(projects = nil)
    to_sort = projects.nil? ? current_user.projects : projects

    res = to_sort.sort { |p1, p2| p1.name.downcase <=> p2.name.downcase }

    if projects.nil?
      res += current_user.completed_projects.sort do |p1, p2|
        p1.name.downcase <=> p2.name.downcase
      end
    end
    
    return res
  end

  ###
  # Returns a css style to apply to an element that should
  # only be shown on a timesheet report.
  ###
  def timesheet_field_style
    display = ""
    if params[:report].nil? || !["3", "2"].include?(params[:report][:type])
      display = "none"
    end

    return "display: #{ display }"
  end
end
