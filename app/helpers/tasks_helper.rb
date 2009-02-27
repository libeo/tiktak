module TasksHelper

  def pri_color(severity, priority)
    color = "#b0d295"
    color = "#f2ab99" if (priority + severity)/2.0 > 0.5
    color = "#FF6666" if (priority + severity)/2.0 > 1.5
    color = "#e7e0c4" if (priority + severity)/2 < -0.5
    color = "#F3F3F3" if (priority + severity)/2 < -1.5

    " style = \"background-color: #{color};\""

  end

  def print_title
    filters = []
    title = "<div style=\"float:left\">"
    status_ids = TaskFilter.filter_status_ids(session)
    if status_ids.any?
      statuses = status_ids.map { |id| Task.status_types[id] }
      title << " #{ _('%s tasks', statuses.join(", ")) } ["
    else
      title << "#{_'Tasks'} ["
    end

    if session[:filter_customer].to_i > 0
      filters << Customer.find(session[:filter_customer].to_i).name
    end

    if session[:filter_project].to_i > 0
      filters << Project.find(session[:filter_project].to_i).name
    end

    TaskFilter.filter_user_ids(session, false).each do |id|
      next if id == 0
      filters << User.find(id).name
    end

    filters << current_user.company.name if filters.empty?

    title << filters.join(' / ')

    title << "]</div><div style=\"float:right\">#{tz.now.strftime_localized("#{current_user.time_format} #{current_user.date_format}")}</div><div style=\"clear:both\"></div>"

    "<h3>#{title}</h3>"

  end

  def task_shown?(t)

    shown = true

    # N.B. Is this still necessary? It seems like the deciding which 
    # tasks is already done in the controller.

    # if session[:filter_status].to_i >= 0
    #   if session[:filter_status].to_i == 0
    #     shown = ( t.status == 0 || t.status == 1 ) if shown
    #   elsif session[:filter_status].to_i == 2
    #     shown = t.status > 1 if shown
    #   else
    #     shown = session[:filter_status].to_i == t.status if shown
    #   end
    # end

    if session[:filter_milestone].to_i > 0 && shown
      shown = session[:filter_milestone].to_i == t.milestone_id if shown
    end

    if session[:filter_customer].to_i > 0 && shown
      shown = session[:filter_customer].to_i == t.project.customer_id if shown
    end

    if session[:filter_project].to_i > 0 && shown
      shown = session[:filter_project].to_i == t.project_id if shown
    end

    user_ids = TaskFilter.filter_user_ids(session, false)
    if shown && user_ids.any?
      task_user_ids = t.users.map { |u| u.id }
      overlap = task_user_ids - user_ids
      shown = overlap.any?
    elsif shown && TaskFilter.filter_user_ids(session, true).any?
      shown = t.users.empty?
    end


    shown
  end

  def render_task_dependants(t, depth, root_present)
    res = ""
    @printed_ids ||= []

    return if @printed_ids.include? t.id

    shown = task_shown?(t)

    @deps = []

    if session[:hide_dependencies].to_i == 1
      res << render(:partial => "task_row", :locals => { :task => t, :depth => depth})
    else 
      unless root_present
        root = nil
        parents = []
        p = t
        while(!p.nil? && p.dependencies.size > 0)
          root = nil
          p.dependencies.each do |dep|
            root = dep if((!dep.done?) && (!@deps.include?(dep.id) ) )
          end
          root ||= p.dependencies.first if(p.dependencies.first.id != p.id && !@deps.include?(p.dependencies.first.id))
          p = root
          @deps << root.id
        end
        res << render_task_dependants(root, depth, true) unless root.nil?
      else
        res << render(:partial => "task_row", :locals => { :task => t, :depth => depth, :override_filter => !shown }) if( ((!t.done?) && t.dependants.size > 0) || shown)

        @printed_ids << t.id

        if t.dependants.size > 0
          t.dependants.each do |child|
            next if @printed_ids.include? child.id
            res << render_task_dependants(child, (((!t.done?) && t.dependants.size > 0) || shown) ? (depth == 0 ? depth + 2 : depth + 1) : depth, true )
          end
        end
      end 
    end
    res
  end

end
