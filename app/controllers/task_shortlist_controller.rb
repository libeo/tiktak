class TaskShortlistController < ApplicationController

  def quick_add
    self.new
  end

  def init
    options = {
      :select => 'tasks.task_num, tasks.name, tasks.due_at, tasks.description, tasks.milestone_id, tasks.duration, tasks.worked_minutes, tasks.project_id, tasks.status, tasks.description, tasks.due_at, tasks.repeat, tasks.requested_by,
        dependencies_tasks.task_num, dependencies_tasks.name, dependencies_tasks.due_at, dependencies_tasks.description, dependencies_tasks.milestone_id, dependencies_tasks.duration, dependencies_tasks.worked_minutes, dependencies_tasks.project_id, dependencies_tasks.status, dependencies_tasks.description, dependencies_tasks.due_at, dependencies_tasks.repeat, dependencies_tasks.requested_by,
        projects.name,
        customers.name,
        users.name, users.company_id, users.email,
        milestones.name,
        tags.name',
      :include => [{:project => :customer}, :users, :milestone, :tags, :dependencies, :notifications]
    }
    session[:channels] += ["tasks_#{current_user.company_id}"]

    f = current_shortlist_filter
    selected = f.qualifiers.select { |q| !["User", "Status"].include?(q.qualifiable_type) }.first
    options[:order], include = order_condition(selected)

    @filter = selected ? qualifier_to_indice(selected) : ""
    @tasks = f.tasks(nil, options)

    #TODO : remove this ?
    @tags = {}
    @tags_total = 0
    @group_ids, @groups = group_tasks(@tasks)
  end



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

  def filter_shortlist
    f = current_shortlist_filter

    i = indice_to_qualifier(params[:filter])
    q = default_shortlist_qualifiers
    q << i if i
    f.qualifiers = q
    f.save

    redirect_to :controller => 'task_shortlist', :action => 'index'
  end

  #!!!
  def create_shortlist_ajax
    @highlight_target = "shortlist"
    if !params[:task][:name] || params[:task][:name].empty?
      render(:highlight) and return
    end

    p = {}
    f = current_shortlist_filter.qualifiers.select { |q| q.qualifiable_type != 'User' }.first

    case f.qualifiable_type
      when 'Milestone':
        p[:miletsone] = Milestone.find_by_id(f.qualifiable_id)
        project = Project.find_by_id(f.qualifiable_id)
      when 'Project':
        project = Project.find_by_id(f.qualifiable_id)
    end

    @task = Task.create_for_user(current_user, project, p)
    
    unless @task
      render :hightlight and return
    else
      @highlight_target = "quick_add_container"

      WorkLog.create_for_task(@task, current_user, _("Created tyhrough the shortlist"))

      if params['notify'].to_i == 1
        Notifications::deliver_created( @task, current_user, params[:comment]) rescue begin end
      end
    end

    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'activities', :action => 'refresh')}');", ["activity_#{current_user.company_id}"])
  end


  def swap_work_ajax
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

  def start_work_ajax
    if @current_sheet
      self.swap_work_ajax
    end

    task = Task.find(params[:id], :conditions => ["task_owners.user_id = ?", current_user.id], :include => :task_owners)
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

      render 'tasks/start_work_ajax'
      return if request.xhr?
    end
  end

  def stop_work
    unless @current_sheet
      render :nothing => true
      return
    end

    @task = @current_sheet.task
    swap_work_ajax
    Juggernaut.send( "do_update(#{current_user.id}, '#{url_for(:controller => 'tasks', :action => 'update_tasks', :id => @task.id)}');", ["tasks_#{current_user.company_id}"])
  end

  def index
    self.init
  end

  private
  ###
  # Returns a two element array containing the grouped tasks.
  # The first element is an in-order array of group ids / names
  # The second element is a hash mapping group ids / names to arrays of tasks.
  ###
  
  def order_condition(order)
    order = self.qualifier_to_indice(order) unless order.is_a? String
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


  #TODO: remove this ?
  def group_tasks(tasks)
    group_ids = {}
    groups = []
    rechecked = false

    if session[:group_by].to_i == 1 # tags
      @tag_names = @all_tags.collect{|i,j| i}
      groups = Task.tag_groups(current_user.company_id, @tag_names, tasks)
    elsif session[:group_by].to_i == 2 # Clients
      clients = Customer.find(:all, :conditions => ["company_id = ?", current_user.company_id], :order => "name")
      clients.each { |c| group_ids[c.name] = c.id }
      items = clients.collect(&:name).sort
      groups = Task.group_by(tasks, items) { |t,i| t.project.customer.name == i }
    elsif session[:group_by].to_i == 3 # Projects
      projects = current_user.projects
      projects.each { |p| group_ids[p.full_name] = p.id }
      items = projects.collect(&:full_name).sort
      groups = Task.group_by(tasks, items) { |t,i| t.project.full_name == i }

    elsif session[:group_by].to_i == 4 and rechecked # Milestones
      tf = TaskFilter.new(self, session)

      if tf.milestone_ids.any?
        filter = " AND id in (#{ tf.milestone_ids.join(",") })"
      elsif tf.project_ids.any?
        filter = " AND project_id in (#{ tf.project_ids.join(",") })"
      elsif tf.customer_ids.any?
        projects = []
        tf.customer_ids.each { |id| projects += Customer.find(id).projects }
        projects = projects.map { |p| p.id }
        filter = " AND project_id IN (#{ projects.join(",") })"
      end

      conditions = "company_id = #{ current_user.company.id }"
      conditions += " AND project_id IN (#{current_project_ids_query})#{filter} "
      conditions += " AND completed_at IS NULL"

      milestones = Milestone.find(:all, :conditions => conditions, 
                                  :order => "due_at, name")
      milestones.each { |m| group_ids[m.name + " / " + m.project.name] = m.id }
      group_ids['Unassigned'] = 0
      items = ["Unassigned"] +  milestones.collect{ |m| m.name + " / " + m.project.name }
      groups = Task.group_by(tasks, items) { |t,i| (t.milestone ? (t.milestone.name + " / " + t.project.name) : "Unassigned" ) == i }

    elsif session[:group_by].to_i == 5 # Users
      unassigned = _("Unassigned")

      # only get users in currently shown tasks
      users = tasks.inject([]) { |array, task| array += task.users }
      users = users.uniq.sort_by { |u| u.name }

      users.each { |u| group_ids[u.name] = u.id }
      group_ids[unassigned] = 0
      items = [ unassigned ] + users.map { |u| u.name }

      groups = Task.group_by(tasks, items) { |t,i|
        if t.users.size > 0
          res = t.users.collect(&:name).include? i
        else
          res = (_("Unassigned") == i)
        end

        res
      }
    elsif session[:group_by].to_i == 7 # Status
      0.upto(5) { |i| group_ids[ _(Task.status_types[i]) ] = i }
      items = Task.status_types.collect{ |i| _(i) }
      groups = Task.group_by(tasks, items) { |t,i| _(t.status_type) == i }
    elsif session[:group_by].to_i == 10 # Projects / Milestones
      milestones = Milestone.find(:all, :conditions => ["company_id = ? AND project_id IN (#{current_project_ids_query}) AND completed_at IS NULL", current_user.company_id], :order => "due_at, name")
      projects = current_user.projects

      milestones.each { |m| group_ids["#{m.project.name} / #{m.name}"] = "#{m.project_id}_#{m.id}" }
      projects.each { |p| group_ids["#{p.name}"] = p.id }

      items = milestones.collect{ |m| "#{m.project.name} / #{m.name}" }.flatten
      items += projects.collect(&:name)
      items = items.uniq.sort

      groups = Task.group_by(tasks, items) { |t,i| t.milestone ? ("#{t.project.name} / #{t.milestone.name}" == i) : (t.project.name == i)  }
    elsif session[:group_by].to_i == 11 # Requested By
      requested_by = tasks.collect{|t| t.requested_by.blank? ? nil : t.requested_by }.compact.uniq.sort
      requested_by = [_('No one')] + requested_by
      groups = Task.group_by(tasks, requested_by) { |t,i| (t.requested_by.blank? ? _('No one') : t.requested_by) == i }
    elsif (property = Property.find_by_group_by(current_user.company, session[:group_by]))
      items = property.property_values
      items.each { |pbv| group_ids[pbv] = pbv.id }

      # add in for tasks without values
      unassigned = _("Unassigned")
      group_ids[unassigned] = 0
      items = [ unassigned ] + items

      groups = Task.group_by(tasks, items) do |task, match_value|
        value = task.property_value(property)
        group = (value and value == match_value)
        group ||= (value.nil? and match_value == unassigned)
        group
      end
    else
      groups = [tasks]
    end

    return [ group_ids, groups ]
  end
end
