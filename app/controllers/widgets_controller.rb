class WidgetsController < ApplicationController

  OVERDUE    = 0
  TODAY      = 1
  TOMORROW   = 2
  THIS_WEEK  = 3
  NEXT_WEEK  = 4

  TASK_ROW_SELECT = 'tasks.name, tasks.hidden, tasks.duration, tasks.worked_minutes, tasks.milestone_id, tasks.due_at, tasks.completed_at, tasks.status, tasks.task_num, tasks.requested_by, tasks.description, tasks.repeat, tasks.company_id,
  dependencies_tasks.task_num, dependants_tasks.task_num, dependencies_tasks.description, dependants_tasks.description,
  projects.name,
  projects.company_id,
  tags.name,
  task_owners.unread, task_owners.user_id,
  notifications.unread, notifications.user_id,
  customers.name, customers.company_id,
  milestones.name,
  users.name, users.company_id, users.email,
  todos.name, todos.completed_at,
  task_property_values.id,
  property_values.id, property_values.color, property_values.value, property_values.icon_url'

  TASK_ROW_INCLUDE = [:milestone, {:project => :customer}, :dependencies, :dependants, :todos, :tags, {:task_owners => :user }, :notifications, {:task_property_values => [:property_value, :property]}]
  #TASK_ROW_INCLUDE = [:milestone, {:project => :customer}, :dependencies, :dependants, :tags, {:task_owners => :user }, :notifications]

  def show
    begin
      @widget = Widget.find(params[:id], :conditions => ["company_id = ? AND user_id = ?", current_user.company_id, current_user.id])
    rescue
      render :nothing => true
      return
    end

    unless @widget.configured?
      render :update do |page|
        page.insert_html :before, "content_#{@widget.dom_id}", :partial => "widget_#{@widget.widget_type}_config"
        page.show "config-#{@widget.dom_id}"
      end
      return
    end
    
    case @widget.widget_type
    when 11
      #Task filter
      order, extra, includes = @widget.order_by_sql
      @items = @widget.filter.tasks(extra, :limit => @widget.number, :order => order, :include => TASK_ROW_INCLUDE + includes, :select => TASK_ROW_SELECT)
      
    when 0
      # Tasks
      filter = filter_from_filter_by

      conditions = ["tasks.project_id in (#{current_project_ids_query})",
        "(tasks.completed_at is null or tasks.hide_until < '#{tz.now.utc.to_s(:db)}')",
        "(tasks.milestone_id not in (#{completed_milestone_ids_query}))",
      ]
      conditions << "tasks.id in (select task_id from task_owners where task_owners.user_id = #{current_user.id})" if @widget.mine?
      #conditions << "task_owners.user_id = #{current_user.id}" if @widget.mine?
      conditions << filter if filter
      order, extra, includes = @widget.order_by_sql
      conditions << extra if extra.length > 0
      
      @items = Task.find(:all, :conditions => conditions.join(" AND "), :include => TASK_ROW_INCLUDE + includes, :order => order, :limit => @widget.number, :select => TASK_ROW_SELECT)

    when 1
      # Project List
      @projects = current_user.projects.find(:all, :order => 'customers.name, projects.name, milestones.due_at IS NULL, milestones.due_at, milestones.name', 
                                             :conditions => ["projects.completed_at IS NULL"], 
                                             :include => [ :customer, :milestones], 
                                             :select => 'projects.name, projects.critical_count, projects.normal_count, projects.low_count, projects.total_tasks, projects.open_tasks,
                                             milestones.completed_tasks, milestones.total_tasks, milestones.project_id, milestones.name, milestones.description, projects.total_milestones, projects.open_milestones, projects.company_id,
                                             customers.name')
      @completed_projects = current_user.completed_projects.size
    when 2
      # Activities
      @activities = EventLog.find(:all, :order => "event_logs.created_at DESC", :limit => @widget.number, 
          :conditions => ["company_id = ? AND (event_logs.project_id IN ( #{current_project_ids} ) OR event_logs.project_id IS NULL)", current_user.company_id]
        )
    when 3
      # Tasks Graph
      case @widget.number
      when 7
        start = tz.local_to_utc(6.days.ago.midnight)
        step = 1
        interval = 1.day / step
        range = 7
        tick = "%a"
      when 30 
        start = tz.local_to_utc(tz.now.beginning_of_week.midnight - 5.weeks)
        step = 2
        interval = 1.week / step
        range = 6
        tick = _("Week") + " %W"
      when 180
        start = tz.local_to_utc(tz.now.beginning_of_month.midnight - 5.months)
        step = 4
        interval = 1.month / step
        range = 6
        tick = "%b"
      end

      filter = filter_from_filter_by
      
      @items = []
      @dates = []
      @range = []
      0.upto(range * step) do |d|
        
        conditions = ["project_id IN (#{current_project_ids_query})",
          "created_at < '#{start + d*interval}'",
            "(completed_at IS NULL OR completed_at > '#{start + d*interval}')",
        ]
        conditions << filter if filter
        unless @widget.mine?
          @items[d] = current_user.company.tasks.count(:conditions => conditions.join(" AND ") )
        else 
          @items[d] = current_user.tasks.count(:conditions => conditions)
        end
        
        @dates[d] = tz.utc_to_local(start + d * interval - 1.hour).strftime(tick) if(d % step == 0)
        @range[0] ||= @items[d]
        @range[1] ||= @items[d]
        @range[0] = @items[d] if @range[0] > @items[d]
        @range[1] = @items[d] if @range[1] < @items[d]
      end
    when 4
      # Burndown
      case @widget.number
      when 7
        start = tz.local_to_utc(6.days.ago.midnight)
        step = 1
        interval = 1.day / step
        range = 7
        tick = "%a"
      when 30 
        start = tz.local_to_utc(tz.now.beginning_of_week.midnight - 5.weeks)
        step = 2
        interval = 1.week / step
        range = 6
        tick = _("Week") + " %W"
      when 180
        start = tz.local_to_utc(tz.now.beginning_of_month.midnight - 5.months)
        step = 4
        interval = 1.month / step
        range = 6
        tick = "%b"
      end

      filter = filter_from_filter_by

      @items = []
      @dates = []
      @range = []
      velocity = 0
      0.upto(range * step) do |d|
        
        unless @widget.mine?
          @items[d] = current_user.company.tasks.sum('duration', :conditions => ["project_id IN (#{current_project_ids}) AND created_at < ? AND (completed_at IS NULL OR completed_at > ?) #{filter}", start + d*interval, start + d*interval]).to_f / current_user.workday_duration 
          worked = current_user.company.tasks.sum('work_logs.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.created_at < ? AND (tasks.completed_at IS NULL OR tasks.completed_at > ?) #{filter} AND tasks.duration > 0 AND work_logs.started_at < ?", start + d*interval, start + d*interval, start + d*interval], :include => :work_logs).to_f / (current_user.workday_duration * 60)
          @items[d] = (@items[d] - worked > 0) ? (@items[d] - worked) : 0
          
        else 
          @items[d] = current_user.tasks.sum('duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND created_at < ? AND (completed_at IS NULL OR completed_at > ?) #{filter}", start + d*interval, start + d*interval]).to_f / current_user.workday_duration
          worked = current_user.tasks.sum('work_logs.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.created_at < ? AND (tasks.completed_at IS NULL OR tasks.completed_at > ?) #{filter} AND tasks.duration > 0 AND work_logs.started_at < ?", start + d*interval, start + d*interval, start + d*interval], :include => :work_logs).to_f / (current_user.workday_duration * 60)
          @items[d] = (@items[d] - worked > 0) ? (@items[d] - worked) : 0
        end
        
        @dates[d] = tz.utc_to_local(start + d * interval - 1.hour).strftime(tick) if(d % step == 0)
        @range[0] ||= @items[d]
        @range[1] ||= @items[d]
        @range[0] = @items[d] if @range[0] > @items[d]
        @range[1] = @items[d] if @range[1] < @items[d]

      end
      
      velocity = (@items[0] - @items[-1]) / ((interval * range * step) / 1.day)
      velocity = velocity * (interval / 1.day)
      
      logger.info("Burndown Velocity: #{velocity}")

      @end_date = nil
      if velocity > 0.0
        days_left = @items[-1] / (velocity)
        @end_date = Time.now + days_left.days
        logger.info("Burndown Velocity left #{@items[-1]}")
        logger.info("Burndown Velocity days: #{days_left}")
        logger.info("Burndown Velocity End date: #{@end_date}")
      end
            
      start = @items[0]
      
      @velocity = []
      0.upto(range * step) do |d|
        @velocity[d] = start - velocity * d
      end 
      
    when 5
      # Burnup
      case @widget.number
      when 7
        start = tz.local_to_utc(6.days.ago.midnight)
        step = 1
        interval = 1.day / step
        range = 7
        tick = "%a"
      when 30 
        start = tz.local_to_utc(tz.now.beginning_of_week.midnight - 5.weeks)
        step = 2
        interval = 1.week / step
        range = 6
        tick = _("Week") + " %W"
      when 180
        start = tz.local_to_utc(tz.now.beginning_of_month.midnight - 5.months)
        step = 4
        interval = 1.month / step
        range = 6
        tick = "%b"
      end

      filter = filter_from_filter_by

      @items  = []
      @totals = []
      @dates  = []
      @range  = []
      velocity = 0
      0.upto(range * step) do |d|
        
        unless @widget.mine? 
          @totals[d]  = Task.sum('duration', :conditions => ["project_id IN (#{current_project_ids}) AND #{filter} AND created_at < ? AND tasks.duration > 0", start + d*interval]).to_f / current_user.workday_duration
          @totals[d] += Task.sum('work_logs.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) #{filter} AND tasks.created_at < ? AND tasks.duration = 0 AND work_logs.started_at < ?", start + d*interval, start + d*interval], :include => :work_logs).to_f / (current_user.workday_duration * 60)

          @items[d] = Task.sum('tasks.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND #{filter}  AND (completed_at IS NOT NULL AND completed_at < ?) AND tasks.created_at < ?  AND tasks.duration > 0", start + d*interval, start + d*interval]).to_f / current_user.workday_duration
          @items[d] += Task.sum('work_logs.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND #{filter} AND tasks.created_at < ? AND (tasks.completed_at IS NULL OR tasks.completed_at > ?) AND tasks.duration = 0 AND work_logs.started_at < ?", start + d*interval, start + d*interval, start + d*interval], :include => :work_logs).to_f / (current_user.workday_duration * 60)
        else 
          @totals[d]  = current_user.tasks.sum('duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND #{filter} AND created_at < ? AND tasks.duration > 0", start + d*interval]).to_f / current_user.workday_duration
          @totals[d] += current_user.tasks.sum('work_logs.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND #{filter} AND tasks.created_at < ? AND tasks.duration = 0 AND work_logs.started_at < ?", start + d*interval, start + d*interval], :include => :work_logs).to_f / (current_user.workday_duration * 60)
          
          @items[d] = current_user.tasks.sum('tasks.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND #{filter} AND (completed_at IS NOT NULL AND completed_at < ?) AND tasks.created_at < ?  AND tasks.duration > 0", start + d*interval, start + d*interval]).to_f / current_user.workday_duration 
          @items[d] += current_user.tasks.sum('work_logs.duration', :conditions => ["tasks.project_id IN (#{current_project_ids}) AND #{filter} AND tasks.created_at < ?  AND tasks.duration = 0 AND (tasks.completed_at IS NULL OR tasks.completed_at > ?) AND work_logs.started_at < ?", start + d*interval, start + d*interval, start + d*interval], :include => :work_logs).to_f / (current_user.workday_duration * 60)
        end
        
        @dates[d] = tz.utc_to_local(start + d * interval - 1.hour).strftime(tick) if(d % step == 0)
        @range[0] ||= @items[d]
        @range[1] ||= @items[d]
        @range[0] = @items[d] if @range[0] > @items[d]
        @range[1] = @items[d] if @range[1] < @items[d]

        @range[0] = @totals[d] if @range[0] > @totals[d]
        @range[1] = @totals[d] if @range[1] < @totals[d]

      end
      
      velocity = (@items[0] - @items[-1]) / ((interval * range * step) / 1.day)
      velocity = velocity * (interval/1.day)
      
      logger.info("Burnup Velocity: #{velocity}")
      @end_date = nil
      if velocity < 0.0
        days_left = (@totals[-1] - @items[-1]) / (-velocity)
        @end_date = Time.now + days_left.days
        logger.info("Burnup Velocity left: #{@totals[-1] - @items[-1]}")
        logger.info("Burnup Velocity days: #{days_left}")
        logger.info("Burnup Velocity End date: #{@end_date}")
      end

      start = @items[0]
      
      @velocity = []
      0.upto(range * step) do |d|
        @velocity[d] = start - velocity * d
      end 
    when 6
      # Comments
      if @widget.mine?
        @items = WorkLog.find(:all, :select => "work_logs.*", :joins => "INNER JOIN tasks ON work_logs.task_id = tasks.id INNER JOIN task_owners ON work_logs.task_id = task_owners.task_id", :conditions => ["work_logs.project_id IN (#{current_project_ids}) AND (work_logs.log_type = ? OR work_logs.comment = 1) AND task_owners.user_id = ?", EventLog::TASK_COMMENT, current_user.id], :order => "started_at desc", :limit => @widget.number)
      else 
        @items = WorkLog.find(:all, :select => "work_logs.*", :joins => "INNER JOIN tasks ON work_logs.task_id = tasks.id", :conditions => ["work_logs.project_id IN (#{current_project_ids}) AND (work_logs.log_type = ? OR work_logs.comment = 1)", EventLog::TASK_COMMENT], :order => "started_at desc", :limit => @widget.number)
      end
    when 7
      # Schedule

      filter = filter_from_filter_by
      filter = 'AND '+filter if filter

      if @widget.mine?
        tasks = current_user.tasks.find(:all, :include => [:users, :tags, :sheets, :todos, :dependencies, :dependants, { :project => :customer}, :milestone ], :conditions => ["tasks.completed_at IS NULL AND projects.completed_at IS NULL #{filter if filter} AND (tasks.due_at IS NOT NULL OR tasks.milestone_id IS NOT NULL)"])
      else 
        tasks = Task.find(:all, :include => [:users, :tags, :sheets, :todos, :dependencies, :dependants, { :project => :customer}, :milestone ], :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.completed_at IS NULL AND projects.completed_at IS NULL #{filter if filter} AND (tasks.due_at IS NOT NULL OR tasks.milestone_id IS NOT NULL)"])
      end
      # first use default sorting
      tasks = tasks.sort_by do |t| 
        [ t.due_date.to_i, t.milestone_id, - current_user.company.rank_by_properties(t) ]
      end
      @tasks = []
      
      tasks.each do |t|
        next if t.due_date.nil?
        
        if t.overdue?
          (@tasks[OVERDUE] ||= []) << t
        elsif t.due_date < ( tz.local_to_utc(tz.now.utc.tomorrow.midnight) )
          (@tasks[TODAY] ||= []) << t
        elsif t.due_date < ( tz.local_to_utc(tz.now.utc.since(2.days).midnight) )
          (@tasks[TOMORROW] ||= []) << t
        elsif t.due_date < ( tz.local_to_utc(tz.now.utc.next_week.beginning_of_week) )
          (@tasks[THIS_WEEK] ||= []) << t
        elsif t.due_date < ( tz.local_to_utc(tz.now.utc.since(2.weeks).beginning_of_week) )
          (@tasks[NEXT_WEEK] ||= []) << t
        end
      end
      
    when 8 
      # Google Gadget
    when 9 
      # Work Status
      filter = filter_from_filter_by

      start = tz.local_to_utc(tz.now.at_midnight)

      @counts = { }

      [:work, :completed, :created].each do |t|
        @counts[t] = []
      end
      
      if @widget.mine?
        @last_completed = current_user.tasks.find(:all, :conditions => "completed_at IS NOT NULL AND #{filter}", :order => "completed_at DESC", :limit => @widget.number)
        @counts[:work][0] = WorkLog.sum('work_logs.duration', :joins => :task, :conditions => ["user_id = ? AND started_at >= ? AND started_at < ? AND #{filter}", current_user.id, start, start + 1.day]).to_i / 60
        @counts[:work][1] = WorkLog.sum('work_logs.duration', :joins => :task, :conditions => ["user_id = ? AND started_at >= ? AND started_at < ? AND #{filter}", current_user.id, start - 1.day, start]).to_i / 60
        @counts[:work][2]  = WorkLog.sum('work_logs.duration', :joins => :task, :conditions => ["user_id = ? AND started_at >= ? AND started_at < ? AND #{filter}", current_user.id, start - 6.days, start + 1.day]).to_i / 60
        @counts[:work][3] = WorkLog.sum('work_logs.duration', :joins => :task, :conditions => ["user_id = ? AND started_at >= ? AND started_at < ? AND #{filter}", current_user.id, start - 29.days, start + 1.day]).to_i / 60
        
        @counts[:completed][0] = current_user.tasks.count(:conditions => ["completed_at IS NOT NULL AND completed_at >= ? AND completed_at < ? AND #{filter}", start, start + 1.day])
        @counts[:completed][1] = current_user.tasks.count(:conditions => ["completed_at IS NOT NULL AND completed_at >= ? AND completed_at < ? AND #{filter}", start - 1.day, start])
        @counts[:completed][2] = current_user.tasks.count(:conditions => ["completed_at IS NOT NULL AND completed_at >= ? AND completed_at < ? AND #{filter}", start - 6.days, start + 1.day])
        @counts[:completed][3] = current_user.tasks.count(:conditions => ["completed_at IS NOT NULL AND completed_at >= ? AND completed_at < ? AND #{filter}", start - 29.days, start + 1.day])
        
        @counts[:created][0] = current_user.tasks.count(:conditions => ["created_at >= ? AND created_at < ? AND #{filter}", start, start + 1.day])
        @counts[:created][1] = current_user.tasks.count(:conditions => ["created_at >= ? AND created_at < ? AND #{filter}", start - 1.day, start])
        @counts[:created][2] = current_user.tasks.count(:conditions => ["created_at >= ? AND created_at < ? AND #{filter}", start - 6.days, start + 1.day])
        @counts[:created][3] = current_user.tasks.count(:conditions => ["created_at >= ? AND created_at < ? AND #{filter}", start - 29.days, start + 1.day])
      else 
        @last_completed = current_user.company.tasks.find(:all, :conditions => "tasks.project_id IN (#{current_project_ids}) AND tasks.completed_at IS NOT NULL AND #{filter}", :order => "tasks.completed_at DESC", :limit => @widget.number)
        @counts[:work][0] = WorkLog.sum('work_logs.duration', :joins => :task, :conditions => ["tasks.project_id IN (#{current_project_ids}) AND started_at >= ? AND started_at < ? AND #{filter}", start, start + 1.day]).to_i / 60
        @counts[:work][1] = WorkLog.sum('work_logs.duration', :joins => :task, :conditions => ["tasks.project_id IN (#{current_project_ids}) AND started_at >= ? AND started_at < ? AND #{filter}", start - 1.day, start]).to_i / 60
        @counts[:work][2] = WorkLog.sum('work_logs.duration', :joins => :task, :conditions => ["tasks.project_id IN (#{current_project_ids}) AND started_at >= ? AND started_at < ? AND #{filter}", start - 6.days, start + 1.day]).to_i / 60
        @counts[:work][3] = WorkLog.sum('work_logs.duration', :joins => :task, :conditions => ["tasks.project_id IN (#{current_project_ids}) AND started_at >= ? AND started_at < ? AND #{filter}", start - 29.days, start + 1.day]).to_i / 60
        
        @counts[:completed][0] = current_user.company.tasks.count(:conditions => ["tasks.project_id IN (#{current_project_ids}) AND completed_at IS NOT NULL AND completed_at >= ? AND completed_at < ? AND #{filter}", start, start + 1.day])
        @counts[:completed][1] = current_user.company.tasks.count(:conditions => ["tasks.project_id IN (#{current_project_ids}) AND completed_at IS NOT NULL AND completed_at >= ? AND completed_at < ? AND #{filter}", start - 1.day, start])
        @counts[:completed][2] = current_user.company.tasks.count(:conditions => ["tasks.project_id IN (#{current_project_ids}) AND completed_at IS NOT NULL AND completed_at >= ? AND completed_at < ? AND #{filter}", start - 6.days, start + 1.day])
        @counts[:completed][3] = current_user.company.tasks.count(:conditions => ["tasks.project_id IN (#{current_project_ids}) AND completed_at IS NOT NULL AND completed_at >= ? AND completed_at < ? AND #{filter}", start - 29.days, start + 1.day])
        
        @counts[:created][0] = current_user.company.tasks.count(:conditions => ["tasks.project_id IN (#{current_project_ids}) AND created_at >= ? AND created_at < ? AND #{filter}", start, start + 1.day])
        @counts[:created][1] = current_user.company.tasks.count(:conditions => ["tasks.project_id IN (#{current_project_ids}) AND created_at >= ? AND created_at < ? AND #{filter}", start - 1.day, start])
        @counts[:created][2] = current_user.company.tasks.count(:conditions => ["tasks.project_id IN (#{current_project_ids}) AND created_at >= ? AND created_at < ? AND #{filter}", start - 6.days, start + 1.day])
        @counts[:created][3] = current_user.company.tasks.count(:conditions => ["tasks.project_id IN (#{current_project_ids}) AND created_at >= ? AND created_at < ? AND #{filter}", start - 29.days, start + 1.day])
        
      end 
    when 10: 
      filter = filter_from_filter_by

      @sheets = Sheet.find(:all, :order => 'users.name', :include => [ :user, :task, :project ], :conditions => ["tasks.project_id IN (#{current_project_ids}) AND #{filter}"]) 
    end 

    render :update do |page|
      case @widget.widget_type
      when 0, 11
        page.replace_html "content_#{@widget.dom_id}", :partial => 'tasks/task_list', :locals => { :tasks => @items }
      when 1
        page.replace_html "content_#{@widget.dom_id}", :partial => 'activities/project_overview'
      when 2
        page.replace_html "content_#{@widget.dom_id}", :partial => 'activities/recent_work'
      when 3..7
        page.replace_html "content_#{@widget.dom_id}", :partial => "widgets/widget_#{@widget.widget_type}"
      when 8 
        page.replace_html "content_#{@widget.dom_id}", :partial => "widgets/widget_#{@widget.widget_type}"
        page << "document.write = function(s) {"
        page << "$('gadget-wrapper-#{@widget.dom_id}').innerHTML += s;"
        page << "}"
        page << "var e = new Element('script', {id:'gadget-#{@widget.dom_id}'});"
        page << "$('gadget-wrapper-#{@widget.dom_id}').insert({top: e});"
        page << "$('gadget-#{@widget.dom_id}').src=#{@widget.gadget_url.gsub(/&amp;/,'&').gsub(/<script src=/,'').gsub(/><\/script>/,'')};"
      when 9..10
        page.replace_html "content_#{@widget.dom_id}", :partial => "widgets/widget_#{@widget.widget_type}"
      end
      page.call("portal.refreshHeights")
      
    end

  end
  
  def add
    render :update do |page|
      page << "if(! $('add-widget') ) {"
      page.insert_html :top, "widget_col_0", :partial => "widgets/add"
      page.visual_effect :appear, "add-widget"
      page << "} else {"
      page.visual_effect :fade, "add-widget"
      page << "}"
    end
  end

  def destroy
    begin
      @widget = Widget.find(params[:id], :conditions => ["company_id = ? AND user_id = ?", current_user.company_id, current_user.id])
    rescue
      render :nothing => true
      return
    end
    render :update do |page|
      page << "var widget = $('#{@widget.dom_id}').widget;"
      page << "portal.remove(widget);"
    end
    @widget.destroy
  end
  
  def create
    @widget = Widget.new(params[:widget])
    @widget.user = current_user
    @widget.company = current_user.company
    @widget.configured = false
    @widget.column = 0
    @widget.position = 0
    @widget.collapsed = false
    
    unless @widget.save
      render :update do |page|
        page.visual_effect :shake, 'add-widget'
      end
      return
    else 
      render :update do |page|
        page.replace_html 'add-widget', :partial => 'widgets/generate_widget', :locals => {:widget => @widget}
      end
    end

  end

  def edit
    begin
      @widget = Widget.find(params[:id], :conditions => ["company_id = ? AND user_id = ?", current_user.company_id, current_user.id])
    rescue
      render :nothing => true
      return
    end

    render :update do |page|
      page << "if(!$('config-#{@widget.dom_id}' ) ) {"
      page.insert_html :before, "content_#{@widget.dom_id}", :partial => "widget_#{@widget.widget_type}_config"
      page.visual_effect :slide_down, "config-#{@widget.dom_id}"
      page << "} else {"
      page.visual_effect :slide_up, "config-#{@widget.dom_id}"
      page.delay(1) do 
        page.remove "config-#{@widget.dom_id}"
      end
      page << "}"
    end
  end

  def update
    begin
      @widget = Widget.find(params[:id], :conditions => ["company_id = ? AND user_id = ?", current_user.company_id, current_user.id])
    rescue
      render :nothing => true
      return
    end

    @widget.configured = true
    
    if @widget.update_attributes(params[:widget])

      render :update do |page|
        page.remove "config-#{@widget.dom_id}"
        page.replace_html "name-#{@widget.dom_id}", @widget.name
        page << "jQuery.getScript('/widgets/show/#{@widget.id}');"
      end
    end
  end
  
  def save_order
    debugger
    [0,1,2,3,4].each do |c|
      pos = 0
      if params["widget_col_#{c}"]
        params["widget_col_#{c}"].each do |id|
          w = current_user.widgets.find(id.split(/-/)[1]) rescue next
          w.column = c
          w.position = pos
          w.save
          pos += 1
        end
      end
    end 
    render :nothing => true
  end
  
  def toggle_display
    begin
      @widget = current_user.widgets.find(params[:id])
    rescue
      render :nothing => true, :layout => false
      return
    end 
    
    @widget.collapsed = !@widget.collapsed?
    
    render :update do |page|
      if @widget.collapsed?
        page.replace_html "content_#{@widget.dom_id}", ""
        page.replace_html "header_#{@widget.dom_id}", :partial => 'widget_title', :locals => {:widget => @widget}
      else
        page.replace_html "content_#{@widget.dom_id}", t(:loading)
        page.replace_html "header_#{@widget.dom_id}", :partial => 'widget_title', :locals => {:widget => @widget}
        page << "jQuery.getScript('/widgets/show/#{@widget.id}', function(data) { jQuery('#content_#{@widget.dom_id}').hide(); jQuery('#content_#{@widget.dom_id}').fadeIn(500);} );"
      end
      page << "portal.refreshHeights();"
    end
    
    @widget.save
    
  end

  private

  def filter_from_filter_by
    return nil unless @widget.filter_by
    case @widget.filter_by[0..0]
    when 'c'
      "tasks.project_id IN (select id from projects where customer_id = #{@widget.filter_by[1..-1]})"
      #"AND tasks.project_id IN (#{current_user.projects.find(:all, :conditions => ["customer_id = ?", @widget.filter_by[1..-1]]).collect(&:id).compact.join(',') } )"
    when 'p'
      "tasks.project_id = #{@widget.filter_by[1..-1]}"
    when 'm'
      "tasks.milestone_id = #{@widget.filter_by[1..-1]}"
    when 'u'
      "tasks.project_id = #{@widget.filter_by[1..-1]} AND tasks.milestone_id IS NULL"
    else
      nil
    end
  end

end
