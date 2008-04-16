#
# Provide a RSS feed of Project WorkLog activities.
# Author:: Erlend Simonsen (mailto:admin@clockingit.com)
#
class FeedsController < ApplicationController

  require_dependency 'rss/maker'
  require_dependency 'icalendar'
  require_dependency 'google_chart'

  include Icalendar

  session :off

  skip_before_filter :authorize

  def unsubscribe
    if params[:id].nil? || params[:id].empty?
      render :nothing => true, :layout => false
      return
    end 

    user = User.find(:first, :conditions => ["uuid = ?", params[:id]])

    if user.nil?
      render :nothing => true, :layout => false
      return
    end

    user.newsletter = 0
    user.save

    render :text => "You're now unsubscribed.. <br/><a href=\"http://www.clockingit.com\">ClockingIT</a>"

  end

  def get_action(log)
    if log.task && log.task_id > 0
      action = "Completed" if log.log_type == EventLog::TASK_COMPLETED
      action = "Reverted" if log.log_type == EventLog::TASK_REVERTED
      action = "Created" if log.log_type == EventLog::TASK_CREATED
      action = "Modified" if log.log_type == EventLog::TASK_MODIFIED
      action = "Commented" if log.log_type == EventLog::TASK_COMMENT
      action = "Worked" if log.log_type == EventLog::TASK_WORK_ADDED
      action = "Archived" if log.log_type == EventLog::TASK_ARCHIVED
      action = "Restored" if log.log_type == EventLog::TASK_RESTORED
    else
      action = "Note created" if log.log_type == EventLog::PAGE_CREATED
      action = "Note deleted" if log.log_type == EventLog::PAGE_DELETED
      action = "Note modified" if log.log_type == EventLog::PAGE_MODIFIED
      action = "Deleted" if log.log_type == EventLog::TASK_DELETED
      action = "Commit" if log.log_type == EventLog::SCM_COMMIT
    end
    action
  end

  # Get the RSS feed, based on the secret key passed on the url
  def rss
    return if params[:id].empty? || params[:id].nil?

    headers["Content-Type"] = "application/rss+xml"

    # Lookup user based on the secret key
    user = User.find(:first, :conditions => ["uuid = ?", params[:id]])

    if user.nil?
      render :nothing => true, :layout => false
      return
    end

    # Find all Project ids this user has access to
    pids = user.projects.find(:all, :order => "projects.customer_id, projects.name", :conditions => [ "projects.company_id = ? AND completed_at IS NULL", user.company_id ])

    # Find 50 last WorkLogs of the Projects
    unless pids.nil? || pids.empty?
      pids = pids.collect{|p|p.id}.join(',')
      @activities = WorkLog.find(:all, :order => "work_logs.started_at DESC", :limit => 50, :conditions => ["work_logs.project_id IN ( #{pids} )"], :include => [:user, :project, :customer, :task])
    else
      @activities = []
    end

    # Create the RSS
    content = RSS::Maker.make("2.0") do |m|
      m.channel.title = "#{user.company.name} Activities"
      m.channel.link = "http://#{user.company.subdomain}.#{$CONFIG[:domain]}/activities/list"
      m.channel.description = "Last changes from ClockingIT for #{user.name}@#{user.company.name}."
      m.items.do_sort = true # sort items by date

      @activities.each do |log|
        action = get_action(log)

        i = m.items.new_item
        i.title = " #{action}: #{log.task.issue_name}" unless log.task.nil?
        i.title ||= "#{action}"
        i.link = "http://#{user.company.subdomain}.#{$CONFIG[:domain]}/tasks/view/#{log.task.task_num}" unless log.task.nil?
        i.description = log.body unless log.body.nil? || log.body.empty?
        i.date = log.started_at
        i.author = log.user.name unless log.user.nil?
        action = nil
      end
    end

    # Render it inline
    render :text => content.to_s
    @activities = nil
    content = nil
    user = nil

  end


  def to_localtime(tz, time)
    DateTime.parse(tz.utc_to_local(time).to_s)
  end

  def to_duration(dur)
    format_duration(dur, 1, 8 * 60).upcase
  end

  def ical_all
    ical(:all)
  end

  def ical(mode = :personal)

    return if params[:id].nil? || params[:id].empty?

    Localization.lang('en_US')

    headers["Content-Type"] = "text/calendar"

    # Lookup user based on the secret key
    user = User.find(:first, :conditions => ["uuid = ?", params[:id]])

    if user.nil?
      render :nothing => true, :layout => false
      return
    end

    tz = TZInfo::Timezone.get(user.time_zone)

    cached = ""

    # Find all Project ids this user has access to
    pids = user.projects.find(:all, :order => "projects.customer_id, projects.name", :conditions => [ "projects.company_id = ? AND completed_at IS NULL", user.company_id ])



    # Find 50 last WorkLogs of the Projects
    unless pids.nil? || pids.empty?
      pids = pids.collect{|p|p.id}.join(',')
      if mode == :all

        if params['mode'].nil? || params['mode'] == 'logs'
          logger.info("selecting logs")
          @activities = WorkLog.find(:all,
                                     :conditions => ["work_logs.project_id IN ( #{pids} ) AND work_logs.task_id > 0 AND (work_logs.log_type = ? OR work_logs.duration > 0)", EventLog::TASK_WORK_ADDED],
                                     :include => [ :user, { :task => :users, :task => :tags }, :ical_entry  ] )
        end

        if params['mode'].nil? || params['mode'] == 'tasks'
          logger.info("selecting tasks")
          @tasks = Task.find(:all,
                             :conditions => ["tasks.project_id IN (#{pids})" ],
                             :include => [:milestone, :tags, :task_owners, :users, :ical_entry ])
        end

      else

        if params['mode'].nil? || params['mode'] == 'logs'
          logger.info("selecting personal logs")
          @activities = WorkLog.find(:all,
                                     :conditions => ["work_logs.project_id IN ( #{pids} ) AND work_logs.user_id = ? AND work_logs.task_id > 0 AND (work_logs.log_type = ? OR work_logs.duration > 0)", user.id, EventLog::TASK_WORK_ADDED],
                                     :include => [ :user, { :task => :users, :task => :tags }, :ical_entry  ] )
        end

        if params['mode'].nil? || params['mode'] == 'tasks'
          logger.info("selecting personal tasks")
          @tasks = user.tasks.find(:all,
                                   :conditions => ["tasks.project_id IN (#{pids})" ],
                                   :include => [:milestone, :tags, :task_owners, :users, :ical_entry ])
        end
      end

      if params['mode'].nil? || params['mode'] == 'milestones'
          logger.info("selecting milestones")
        @milestones = Milestone.find(:all,
                                     :conditions => ["company_id = ? AND project_id IN (#{pids}) AND due_at IS NOT NULL", user.company_id])
      end

    end
    @activities ||= []
    @tasks ||= []
    @milestones ||= []

    cal = Calendar.new

    @milestones.each do |m|
      event = cal.event

      if m.completed_at
        event.start = to_localtime(tz, m.completed_at)
      else
        event.start = to_localtime(tz, m.due_at)
      end
      event.duration = "PT1M"
      event.uid =  "m#{m.id}_#{event.created}@#{user.company.subdomain}.#{$CONFIG[:domain]}"
      event.organizer = "MAILTO:#{m.user.nil? ? user.email : m.user.email}"
      event.url = "http://#{user.company.subdomain}.#{$CONFIG[:domain]}/views/select_milestone/#{m.id}"
      event.summary = "Milestone: #{m.name}"

      if m.description
        description = m.description.gsub(/<[^>]*>/,'')
        description.gsub!(/\r/, '') if description
        event.description = description if description && description.length > 0
      end
    end


    @tasks.each do |t|

      if t.ical_entry
        cached << t.ical_entry.body
        next
      end

      todo = cal.todo

      unless t.completed_at
        if t.due_at
          todo.start = to_localtime(tz, t.due_at - 12.hours)
        elsif t.milestone && t.milestone.due_at
          todo.start = to_localtime(tz, t.milestone.due_at - 12.hours)
        else
          todo.start = to_localtime(tz, t.created_at)
        end
      else
        todo.start = to_localtime(tz, t.completed_at)
      end

      todo.created = to_localtime(tz, t.created_at)
      todo.uid =  "t#{t.id}_#{todo.created}@#{user.company.subdomain}.#{$CONFIG[:domain]}"
      todo.organizer = "MAILTO:#{t.users.first.email}" if t.users.size > 0
      todo.url = "http://#{user.company.subdomain}.#{$CONFIG[:domain]}/tasks/view/#{t.task_num}"
      todo.summary = "#{t.issue_name}"

      description = t.description.gsub(/<[^>]*>/,'').gsub(/[\r]/, '') if t.description

      todo.description = description if description && description.length > 0
      todo.categories = t.tags.collect{ |tag| tag.name.upcase } if(t.tags.size > 0)
      todo.percent = 100 if t.done?

      event = cal.event
      event.start = todo.start
      event.duration = "PT1M"
      event.created = todo.created
      event.uid =  "te#{t.id}_#{todo.created}@#{user.company.subdomain}.#{$CONFIG[:domain]}"
      event.organizer = todo.organizer
      event.url = todo.url
      event.summary = "#{t.issue_name} - #{t.owners}" unless t.done?
      event.summary = "#{t.status_type} #{t.issue_name} (#{t.owners})" if t.done?
      event.description = todo.description
      event.categories = t.tags.collect{ |tag| tag.name.upcase } if(t.tags.size > 0)


      unless t.ical_entry
        cache = IcalEntry.new( :body => "#{event.to_ical}#{todo.to_ical}", :task_id => t.id )
        cache.save
      end

    end


    @activities.each do |log|

      if log.ical_entry
        cached << log.ical_entry.body
        next
      end

      event = cal.event
      event.start = to_localtime(tz, log.started_at)
#      event.end = to_localtime(tz, log.started_at + (log.duration > 0 ? (log.duration*60) : 60) )
      event.duration = "PT" + (log.duration > 0 ? to_duration(log.duration) : "1M")
      event.created = to_localtime(tz, log.task.created_at) unless log.task.nil?
      event.uid = "l#{log.id}_#{event.created}@#{user.company.subdomain}.#{$CONFIG[:domain]}"
      event.organizer = "MAILTO:#{log.user.email}"

      event.url = "http://#{user.company.subdomain}.#{$CONFIG[:domain]}/tasks/view/#{log.task.task_num}"

      action = get_action(log)

      event.summary = "#{action}: #{log.task.issue_name} - #{log.user.name}" unless log.task.nil?
      event.summary = "#{action} #{to_duration(log.duration).downcase}: #{log.task.issue_name} - #{log.user.name}" if log.duration > 0
      event.summary ||= "#{action} - #{log.user.name}"
      description = log.body.gsub(/<[^>]*>/,'').gsub(/[\r]/, '') if log.body
      event.description = description if description && description.length > 0

      event.categories = log.task.tags.collect{ |t| t.name.upcase } if log.task.tags.size > 0

      unless log.ical_entry
        cache = IcalEntry.new( :body => "#{event.to_ical}", :work_log_id => log.id )
        cache.save
      end

    end

    ical_feed = cal.to_ical
    ical_feed.gsub!(/END:VCALENDAR/,"#{cached}END:VCALENDAR")
    ical_feed.gsub!(/^PERCENT:/, 'PERCENT-COMPLETE:')
    render :text => ical_feed

    ical_feed = nil
    @activities = nil
    @tasks = nil
    @milestones = nil
    tz = nil
    cached = ""
    cal = nil

    GC.start

    ical_feed = nil
    @activities = nil
    @tasks = nil
    @milestones = nil
    tz = nil
    cached = ""
    cal = nil

    GC.start

  end


  def igoogle
    render :layout => false
  end

  def igoogle_feed
    if params[:up_uid].nil? || params[:up_uid].empty?
      render :text => "Please enter your widget key in this gadgets settings. The key can be found on your <a href=\"http://www.clockingit.com\">ClockingIT</a> preferences page.", :layout => false
      return
    end

    user = User.find(:first, :conditions => ["autologin = ?", params[:up_uid]])
    if user.nil?
      render :text => "Wrong Widget key (found on your preferences page)", :layout => false
      return
    end
    tz = TZInfo::Timezone.get(user.time_zone)

    limit = params[:up_show_number] || "5"

    @current_user = user

    @projects = user.projects.find(:all, :order => 't1_r2, projects.name', :conditions => ["projects.completed_at IS NULL"], :include => [ :customer, :milestones]);
    pids = @projects.collect(&:id).join(',')
    if pids.nil? || pids.empty?
        pids = "0"
    end


    if params[:up_show_order] && params[:up_show_order] == "Newest Tasks"
      if params[:up_show_mine] && params[:up_show_mine] == "All Tasks"
        @tasks = Task.find(:all, :conditions => ["tasks.project_id IN (#{pids}) AND tasks.company_id = #{user.company_id} AND tasks.completed_at IS NULL AND (tasks.hide_until IS NULL OR tasks.hide_until < '#{tz.now.utc.to_s(:db)}')"],  :order => "tasks.created_at desc", :include => [:tags, :work_logs, :milestone, { :project => :customer }, :dependencies, :dependants, :users, :work_logs, :todos], :limit => limit.to_i  )
      else
        @tasks = Task.find(:all, :conditions => ["tasks.project_id IN (#{pids}) AND tasks.company_id = #{user.company_id} AND tasks.completed_at IS NULL AND (tasks.hide_until IS NULL OR tasks.hide_until < '#{tz.now.utc.to_s(:db)}') AND tasks.id = task_owners.task_id AND task_owners.user_id = #{user.id}"],  :order => "tasks.created_at desc", :include => [:tags, :work_logs, :milestone, { :project => :customer }, :dependencies, :dependants, :users, :work_logs, :todos], :limit => limit.to_i )
      end
    elsif params[:up_show_order] && params[:up_show_order] == "Top Tasks"
      if params[:up_show_mine] && params[:up_show_mine] == "All Tasks"
        @tasks = Task.find(:all, :conditions => ["tasks.project_id IN (#{pids}) AND tasks.completed_at IS NULL AND tasks.company_id = #{user.company_id} AND (tasks.hide_until IS NULL OR tasks.hide_until < '#{tz.now.utc.to_s(:db)}')"],  :order => "tasks.severity_id + tasks.priority desc, CASE WHEN (tasks.due_at IS NULL AND milestones.due_at IS NULL) THEN 1 ELSE 0 END, CASE WHEN (tasks.due_at IS NULL AND tasks.milestone_id IS NOT NULL) THEN milestones.due_at ELSE tasks.due_at END", :include => [:tags, :work_logs, :milestone, { :project => :customer }, :dependencies, :dependants, :users, :todos ], :limit => limit.to_i  )
      else
        @tasks = Task.find(:all, :conditions => ["tasks.project_id IN (#{pids}) AND tasks.completed_at IS NULL AND tasks.company_id = #{user.company_id} AND (tasks.hide_until IS NULL OR tasks.hide_until < '#{tz.now.utc.to_s(:db)}') AND tasks.id = task_owners.task_id AND task_owners.user_id = #{user.id}"],  :order => "tasks.severity_id + tasks.priority desc, CASE WHEN (tasks.due_at IS NULL AND milestones.due_at IS NULL) THEN 1 ELSE 0 END, CASE WHEN (tasks.due_at IS NULL AND tasks.milestone_id IS NOT NULL) THEN milestones.due_at ELSE tasks.due_at END", :include => [:tags, :work_logs, :milestone, { :project => :customer }, :dependencies, :dependants, :users, :todos ], :limit => limit.to_i  )
      end
    elsif params[:up_show_order] && params[:up_show_order] == "Status Pie-Chart"
      completed = 0
      open = 0
      in_progress = 0

      if params[:up_show_mine] && params[:up_show_mine] == "All Tasks"
        @projects.each do |p|
          open += p.tasks.count(:conditions => ["completed_at IS NULL"])
          completed += p.tasks.count(:conditions => ["completed_at IS NOT NULL"])
          in_progress += p.tasks.count(:conditions => ["completed_at IS NULL AND status = 1"])
        end
        GoogleChart::PieChart.new('280x200', "#{user.company.name} Status", false) do |pc|
          pc.data "Open", open
          pc.data "Closed", completed
          pc.data "In Progress", in_progress
          @chart = pc.to_url
        end
      else
        open = user.tasks.count(:conditions => ["completed_at IS NULL AND project_id IN (#{pids})"])
        completed = user.tasks.count(:conditions => ["completed_at IS NOT NULL AND project_id IN (#{pids})"])
        in_progress = user.tasks.count(:conditions => ["completed_at IS NULL AND status = 1 AND project_id IN (#{pids})"])
        GoogleChart::PieChart.new('280x200', "#{user.company.name} Status", false) do |pc|
          pc.data "Open", open
          pc.data "Closed", completed
          pc.data "In Progress", in_progress
          @chart = pc.to_url
        end
      end
    elsif params[:up_show_order] && params[:up_show_order] == "Priority Pie-Chart"
      critical = 0
      normal = 0
      low = 0

      if params[:up_show_mine] && params[:up_show_mine] == "All Tasks"
        @projects.each do |p|
          critical += p.critical_count
          normal += p.normal_count
          low += p.low_count
        end
        GoogleChart::PieChart.new('280x200', "#{user.company.name} Priorities", false) do |pc|
          pc.data "Critical", critical
          pc.data "Normal", normal
          pc.data "Low", low
          @chart = pc.to_url
        end
      else
        critical = user.tasks.count(:conditions => ["completed_at IS NULL AND project_id IN (#{pids}) AND (severity_id + priority)/2 > 0"])
        normal = user.tasks.count(:conditions => ["completed_at IS NOT NULL AND project_id IN (#{pids}) AND (severity_id + priority)/2 = 0"])
        low = user.tasks.count(:conditions => ["completed_at IS NULL AND project_id IN (#{pids}) AND (severity_id + priority)/2 < 0 "])
        GoogleChart::PieChart.new('280x200', "#{user.name} Priorities", false) do |pc|
          pc.data "Critical", critical
          pc.data "Normal", normal
          pc.data "Low", low
          @chart = pc.to_url
        end
      end
    else
      completed = 0
      open = 0
      in_progress = 0

      if params[:up_show_mine] && params[:up_show_mine] == "All Tasks"
        GoogleChart::PieChart.new('280x200', "#{user.company.name} Projects", false) do |pc|
          @projects.each do |p|
            pc.data p.name, (p.critical_count + p.normal_count + p.low_count)
          end
          @chart = pc.to_url
        end
      else
        GoogleChart::PieChart.new('280x200', "#{user.company.name} Projects", false) do |pc|
          @projects.each do |p|
            pc.data p.name, user.tasks.count(:conditions => ["project_id = ? AND completed_at IS NULL", p.id])
          end
          @chart = pc.to_url
        end
      end
    end

    render :layout => false
  end

end
