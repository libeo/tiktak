class TaskShortlistController < ApplicationController

  TASK_ROW_SELECT = 'tasks.task_num, tasks.name, tasks.due_at, tasks.description, tasks.milestone_id, tasks.duration, tasks.worked_minutes, tasks.project_id, tasks.status, tasks.description, tasks.due_at, tasks.repeat, tasks.requested_by,
        dependencies_tasks.task_num, dependencies_tasks.name, dependencies_tasks.due_at, dependencies_tasks.description, dependencies_tasks.milestone_id, dependencies_tasks.duration, dependencies_tasks.worked_minutes, dependencies_tasks.project_id, dependencies_tasks.status, dependencies_tasks.description, dependencies_tasks.due_at, dependencies_tasks.repeat, dependencies_tasks.requested_by,
        projects.name,
        customers.name,
        users.name, users.company_id, users.email,
        milestones.name,
        tags.name'

  def quick_add
    self.new
  end

  def index
    options = {
      :select => TASK_ROW_SELECT,
      :include => [{:project => :customer}, :users, :milestone, :tags, :dependencies, :notifications]
    }
    session[:channels] += ["tasks_#{current_user.company_id}"]

    f = current_shortlist_filter
    selected = f.qualifiers.select { |q| !["User", "Status"].include?(q.qualifiable_type) }.first
    if selected
      options[:order], include = order_condition(selected)
      @filter = qualifier_to_indice(selected)
    end
    @filter ||= ""
    @tasks = f.tasks(nil, options)
  end

  def filter
    f = current_shortlist_filter

    i = indice_to_qualifier(params[:filter])
    q = default_shortlist_qualifiers
    q << i if i
    f.qualifiers = q
    f.save

    redirect_to :action => 'index'
  end

  def create_ajax
    @highlight_target = "shortlist"
    if !params[:task][:name] || params[:task][:name].empty?
      render(:highlight) and return
    end

    
    p = {:description => _("Task created through the short list")}.merge(params[:task])
    f = current_shortlist_filter.qualifiers.reject { |q| ['User', 'Status'].include? q.qualifiable_type }.first

    project_fields = 'projects.id, projects.name, projects.company_id,
    companies.id,
    customers.id, customers.name
    '
    case f.qualifiable_type
      when 'Milestone':
        p[:milestone] = Milestone.find_by_id(f.qualifiable_id, :select => "id, project_id, name")
        project = Project.find_by_id(p[:milestone].project_id, :select => project_fields, :include => [:company, :customer])
      when 'Project':
        project = Project.find_by_id(f.qualifiable_id, :select => project_fields, :include => [:company, :customer])
    end

    p.each_key { |k| p[k.to_sym] = p[k] and p.delete(k) if !k.is_a? Symbol }
    @task = Task.create_for_user(current_user, project, p)
    @task.properties = {"1" => "1"}
    @task.save
    
    unless @task
      render 'tasks/highlight' and return
    else
      @highlight_target = "quick_add_container"
    end

    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])
  end

  def swap_work
    if @current_sheet

      @old_task = @current_sheet.task

      if @old_task.nil?
        @current_sheet.destroy
        @current_sheet = nil
        redirect_from_last
      end

      if @old_task.close_current_work_log(@current_sheet) 
        @current_sheet.destroy
        flash['notice'] = _("Log entry saved...")
        Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @old_task.id)}');", ["tasks_#{current_user.company_id}"])
        Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])
        @current_sheet = nil
      else
        flash['notice'] = _("Unable to save log entry...")
        redirect_from_last
      end

    end

  end

  def start_work
    if @current_sheet
      self.swap_work
    end

    task = Task.find(params[:id], :conditions => ["(assignments.user_id = ? and assignments.assigned = true) or tasks.project_id in (#{current_project_ids_query})", current_user.id], :include => :assignments)
    if task
      @current_sheet = Sheet.new({
        :task => task,
        :user => current_user,
        :project => task.project,
      })
      @current_sheet.save
      task.status = 1 if task.status == 0
      task.save

      Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => task.id)}');", ["tasks_#{current_user.company_id}"])

      return if request.xhr?
    end
  end
  
  def start_work_ajax
    self.start_work
  end

  def start_work_edit_ajax
    self.start_work
  end

  def cancel_work_ajax
    return if not @current_sheet
    @task = @current_sheet.task
    @current_sheet.destroy
    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
    @current_sheet = nil
  end

  def stop_work_ajax
    self.stop_work
  end

  def stop_work
    unless @current_sheet
      render :nothing => true
      return
    end

    @task = @current_sheet.task
    swap_work
    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
  end

  def ajax_check
    @task = Task.find(params[:id], :conditions => ["tasks.project_id in (#{current_project_ids_query}) and tasks.completed_at is null"], :include => :project)
    render :nothing => true and return unless @task

    info = {}
    if @current_sheet and @current_sheet.task_id == @task.id
      info = {:started_at => @current_sheet.created_at,
        :duration => @current_sheet.duration,
        :paused_duration => @current_sheet.paused_duration,
        :body => @current_sheet.body || "",
        :comment => !@current_sheet.body.blank?,
      }
      close_work_log = true
      swap_work
    end

    @task.close_task(current_user, info)

    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])
  end

  def ajax_uncheck
    @task = Task.find(params[:id], :conditions => ["tasks.project_id in (#{current_project_ids_query}) and tasks.completed_at is null"], :include => :project)
    render :nothing => true and return unless @task

    @task.open_task(current_user)

    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])
  end

  private
  ###
  # Returns a two element array containing the grouped tasks.
  # The first element is an in-order array of group ids / names
  # The second element is a hash mapping group ids / names to arrays of tasks.
  ###
  def qualifier_to_indice(qualifier)
    str = ""
    case qualifier.qualifiable_type
    when 'Customer'
      str += "c"
    when 'Project'
      str += "p"
    when 'Milestone'
      str += 'm'
    when 'NoUser'
      str += 'u'
    when 'Tag'
      str += 't'
    end

    if qualifier.qualifiable_id != 0
      str += qualifier.qualifiable_id.to_s
    end

    return str
  end

  def indice_to_qualifier(indice)
    type = nil
    qualifier = nil
    case indice[0,1]
    when 'c'
      type = 'Customer'
    when 'p'
      type = 'Project'
    when 'm'
      type = 'Milestone'
    when 'u'
      type = 'NoUser'
    when 't'
      type = 'Tag'
    end

    if type  
      id = indice[1, indice.length - 1].to_i
      qualifier = TaskFilterQualifier.new(:qualifiable_type => type, :qualifiable_id => id)
    end

    return qualifier
  end
  
  def order_condition(order)
    order = qualifier_to_indice(order) unless order.is_a? String
    cond = []
    include = []

    case order
      when 't'
        cond << 'tags.name'
        include << :tags
      when 'c'
      when 'm'
        include << :project
        cond << 'projects.name'
      #when 'u'
    end
    cond << 'tasks.name'

    return [cond.join(",") , include]
  end

end
