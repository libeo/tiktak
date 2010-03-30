require "active_record_extensions"

# A task
#
# Belongs to a project, milestone, creator
# Has many tags, users (through task_owners), tags (through task_tags),
#   dependencies (tasks which should be done before this one) and 
#   dependants (tasks which should be done after this one),
#   todos, and sheets
#
class Task < ActiveRecord::Base

  include Misc
  augment RepeatDate
  augment Attributes
  augment Tags
  augment TaskProperties
  augment Assignments
  augment ViewHelpers

  belongs_to    :company
  belongs_to    :project
  belongs_to    :milestone
  has_many      :users, :through => :task_owners, :source => :user
  has_many      :task_owners, :dependent => :destroy

  has_many      :work_logs, :dependent => :destroy, :order => "started_at asc"
  has_many      :attachments, :class_name => "ProjectFile", :dependent => :destroy

  has_many      :notifications, :dependent => :destroy
  has_many      :watchers, :through => :notifications, :source => :user

  belongs_to    :creator, :class_name => "User", :foreign_key => "creator_id"

  belongs_to    :old_owner, :class_name => "User", :foreign_key => "user_id"

  has_and_belongs_to_many  :tags, :join_table => 'task_tags'

  has_and_belongs_to_many  :dependencies, :class_name => "Task", :join_table => "dependencies", :association_foreign_key => "dependency_id", :foreign_key => "task_id", :order => 'dependency_id'
  has_and_belongs_to_many  :dependants, :class_name => "Task", :join_table => "dependencies", :association_foreign_key => "task_id", :foreign_key => "dependency_id", :order => 'task_id'

  has_many :task_property_values, :dependent => :destroy, :include => [ :property ]

  has_many :task_customers, :dependent => :destroy
  has_many :customers, :through => :task_customers, :order => "customers.name asc"
  adds_and_removes_using_params :customers

  has_one       :ical_entry

  has_many      :todos, :order => "completed_at IS NULL desc, completed_at desc, position"
  has_many      :sheets
  has_and_belongs_to_many :resources

  validates_length_of           :name,  :maximum=>200, :allow_nil => true
  validates_presence_of         :name

  validates_presence_of		:company
  validates_presence_of		:project

  before_create :set_task_num

  after_save { |r|
    r.ical_entry.destroy if r.ical_entry
    project = r.project
    project.update_project_stats
    project.save

    if r.project.id != r.project_id
      # Task has changed projects, update counts of target project as well
      p = Project.find(r.project_id)
      p.update_project_stats
      p.save
    end

    r.milestone.update_counts if r.milestone
  }

  def self.per_page
    25
  end

  def recalculate_worked_minutes
    self.worked_minutes = WorkLog.sum(:duration, :conditions => ["task_id = ?", self.id]).to_i / 60
  end


  def full_name
    if self.project
      [self.project.full_name, self.full_tags].join(' / ')
    else 
      ""
    end 
  end

  def full_tags
    self.tags.collect{ |t| "<a href=\"/tasks/list/?tag=#{t.name}\" class=\"description\">#{t.name.capitalize.gsub(/\"/,'&quot;')}</a>" }.join(" / ")
  end

  def full_name_without_links
    [self.project.full_name, self.full_tags_without_links].join(' / ')
  end

  def full_tags_without_links
    self.tags.collect{ |t| t.name.capitalize }.join(" / ")
  end

  def issue_name
    "[##{self.task_num}] #{self[:name]}"
  end

  def issue_num
    if self.status > 1
      "<strike>##{self.task_num}</strike>"
    else
      "##{self.task_num}"
    end
  end

  def status_name
    "#{self.issue_num} #{self.name}"
  end

  def issue_type
    Task.issue_types[self.type_id.to_i]
  end

  def Task.issue_types
    ["Task", "New Feature", "Defect", "Improvement"]
  end

  def status_type
    Task.status_types[self.status]
  end

  def Task.status_type(type)
    Task.status_types[type]
  end

  def Task.status_types
    ["Open", "In Progress", "Closed", "Won't fix", "Invalid", "Duplicate"]
  end

  def priority_type
    Task.priority_types[self.priority]
  end

  def Task.priority_types
    {  -2 => "Lowest", -1 => "Low", 0 => "Normal", 1 => "High", 2 => "Urgent", 3 => "Critical" }
  end

  def severity_type
    Task.severity_types[self.severity_id]
  end

  def Task.severity_types
    { -2 => "Trivial", -1 => "Minor", 0 => "Normal", 1 => "Major", 2 => "Critical", 3 => "Blocker"}
  end

  def owners
    o = self.users.collect{ |u| u.name}.join(', ')
    o = "Unassigned" if o.nil? || o == ""
    o
  end


  def to_s
    self.name
  end

  def Task.group_by(tasks, items, done_items = [], depth = 0)
    groups = OrderedHash.new

    items -= done_items
    items.each do |item|
      unless tasks.nil?
        matching_tasks = tasks.select do |t|
          yield(t,item)
        end
      end
      tasks -= matching_tasks
      unless matching_tasks.empty?
        groups[item] = matching_tasks
      else
        groups[item] = []
      end
    end

    if groups.keys.size > 0
      [tasks, groups]
    else
      [tasks]
    end
  end

  def self.search(user, keys, other_conditions=nil)
    tf = TaskFilter.new(:user => user)

    conditions = []
    keys.each do |k|
      conditions << "tasks.task_num = #{ k.to_i }"
    end
    name_conds = Search.search_conditions_for(keys, [ "tasks.name" ], :search_by_id => false)
    conditions << name_conds[1...-1] # strip off surounding parentheses

    conditions = "(#{ conditions.join(" or ") })"
    conditions += other_conditions if other_conditions
    return tf.tasks(conditions)
  end

  def to_tip(options = { })
    unless @tip
      owners = "No one"
      owners = self.users.collect{|u| u.name}.join(', ') unless self.users.empty?

      res = "<table id=\"task_tooltip\" cellpadding=0 cellspacing=0>"
      res << "<tr><th>#{_('Summary')}</td><td>#{self.name}</tr>"
      res << "<tr><th>#{_('Project')}</td><td>#{self.project.full_name}</td></tr>"
      res << "<tr><th>#{_('Tags')}</td><td>#{self.full_tags}</td></tr>" unless self.full_tags.blank?
      res << "<tr><th>#{_('Assigned To')}</td><td>#{owners}</td></tr>"
      res << "<tr><th>#{_('Requested By')}</td><td>#{self.requested_by}</td></tr>" unless self.requested_by.blank?
      res << "<tr><th>#{_('Status')}</td><td>#{_(self.status_type)}</td></tr>"
      res << "<tr><th>#{_('Milestone')}</td><td>#{self.milestone.name}</td></tr>" if self.milestone_id.to_i > 0
      res << "<tr><th>#{_('Completed')}</td><td>#{options[:user].tz.utc_to_local(self.completed_at).strftime_localized(options[:user].date_format)}</td></tr>" if self.completed_at
      res << "<tr><th>#{_('Due Date')}</td><td>#{options[:user].tz.utc_to_local(due).strftime_localized(options[:user].date_format)}</td></tr>" if self.due
      unless self.dependencies.empty?
        res << "<tr><th valign=\"top\">#{_('Dependencies')}</td><td>#{self.dependencies.collect { |t| t.issue_name }.join('<br />')}</td></tr>"
      end
      unless self.dependants.empty?
        res << "<tr><th valign=\"top\">#{_('Depended on by')}</td><td>#{self.dependants.collect { |t| t.issue_name }.join('<br />')}</td></tr>"
      end
      res << "<tr><th>#{_('Progress')}</td><td>#{format_duration(self.worked_minutes, options[:duration_format], options[:workday_duration], options[:days_per_week])} / #{format_duration( self.duration.to_i, options[:duration_format], options[:workday_duration], options[:days_per_week] )}</tr>"
      res << "<tr><th>#{_('Description')}</th><td class=\"tip_description\">#{self.description_wrapped.gsub(/\n/, '<br/>').gsub(/\"/,'&quot;').gsub(/</,'&lt;').gsub(/>/,'&gt;')}</td></tr>" unless self.description.blank?
      res << "</table>"
      @tip = res.gsub(/\"/,'&quot;')
    end 
    @tip
  end

  def description_wrapped
    unless description.blank?
      truncate( word_wrap(self.description, :line_width => 80), :length => 1000)
    else
      nil
    end
  end 

  def css_classes
    unless @css
      @css = case self.status
             when 0 then ""
             when 1 then " in_progress"
             when 2 then " closed"
             else 
               " invalid"
             end
    end   
    @css
  end

  def todo_status
    todos.empty? ? "[#{_'To-do'}]" : "[#{sprintf("%.2f%%", todos.select{|t| t.completed_at }.size / todos.size.to_f * 100.0)}]"
  end

  def todo_count
    "#{sprintf("%d/%d", todos.select{|t| t.completed_at }.size, todos.size)}"
  end

  def order_date
    [self.started_at.to_i]
  end 

  def worked_and_duration_class
    if worked_minutes > duration
      "overtime"
    else 
      ""
    end 
  end 


  ###
  # Returns an int to use for sorting this task. See Company.rank_by_properties
  # for more info.
  ###
  def sort_rank
    @sort_rank ||= company.rank_by_properties(self)
  end

  ###
  # Generate a cache key from all changing data
  ###
  def cache_expiry(current_user)
    # due / completed ago
    distance_in_minutes = 0
    due_part = "0"
    if done?
      from_time = completed_at
      to_time = Time.now.utc
      distance_in_minutes = (((to_time - from_time).abs)/60).round
    elsif due_date
      from_time = Time.now.utc
      to_time = due_date
      distance_in_minutes = (((to_time - from_time).abs)/60).round
    end 

    if distance_in_minutes > 0
      due_part = case distance_in_minutes
                 when 0..1440     then "00"
                 when 1441..2880   then "10"
                 when 2881..10080  then "2#{(distance_in_minutes / 1440).round.to_s}"
                 when 10081..20160 then "3#{(distance_in_minutes / 1440).round.to_s}"
                 when 20161..43200 then "4#{(distance_in_minutes / 1440 / 7).round.to_s}"
                 when 43201..86400 then "50"
                 else "6#{(distance_in_minutes / 1440 / 30).round.to_s}"
                 end
    end 

    worked_part = worked_on? ? "1#{worked_minutes}" : "0#{worked_minutes}"
    config_part = current_user.show_type_icons? ? "1" : "0" 
    config_part << current_user.option_tracktime.to_s
    locale_part = current_user.locale.to_s

    "#{locale_part}#{due_part}#{worked_part}#{config_part}"
  end 


  ###
  # Sets the dependencies of this this from dependency_params.
  # Existing and unused dependencies WILL be cleared by this method.
  ###
  def set_dependency_attributes(dependency_params, project_ids)
    return if dependency_params.nil?

    new_dependencies = []
    dependency_params.each do |d|
      d.split(",").each do |dep|
        dep.strip!
        next if dep.to_i == 0

        conditions = [ "project_id IN (#{ project_ids }) " +
          " AND task_num = ?", dep ]
          t = Task.find(:first, :conditions => conditions)
          new_dependencies << t if t
      end
    end

    removed = self.dependencies - new_dependencies
    self.dependencies.delete(removed)

    new_dependencies.each do |t|
      existing = self.dependencies.detect { |d| d.id == t.id }
      self.dependencies << t if !existing
    end

    self.save
  end

  ###
  # Sets up any links to resources that should be attached to this
  # task. 
  # Clears any existings links to resources.
  ###
  def set_resource_attributes(params)
    return if !params

    resources.clear

    ids = params[:name].split(",")
    ids += params[:ids] if params[:ids] and params[:ids].any?

    ids.each do |id|
      self.resources << company.resources.find(id)
    end
  end

  ###
  # Custom validation for tasks.
  ###
  def validate
    res = true

    mandatory_properties = company.properties.select { |p| p.mandatory? }
    mandatory_properties.each do |p|
      if !property_value(p)
        res = false
        errors.add_to_base(_("%s is required", p.name))
      end
    end

    return res
  end

  # Creates a new work log for this task using the given params
  def create_work_log(params, user)
    if params and !params[:duration].blank?
      params[:duration] = TimeParser.parse_time(user, params[:duration])
      params[:started_at] = TimeParser.date_from_params(user, params, :started_at)
      if params[:body].blank?
        params[:body] = self.description
      end
      params.merge!(:user => user,
                    :company => self.company, 
                    :project => self.project, 
                    :customer => (self.customers.first || self.project.customer))
      self.work_logs.build(params).save!
    end
  end

  def last_comment
    @last_comment ||= self.work_logs.reverse.detect { |wl| wl.comment? }
  end


  def close_current_work_log(sheet)
    worklog = WorkLog.new({
      :user => sheet.user,
      :company => sheet.user.company,
      :project => sheet.project,
      :task => sheet.task,
      :customer => sheet.project.customer,
      :started_at => sheet.created_at,
      :duration => sheet.duration,
      :paused_duration => sheet.paused_duration,
      :body => sheet.body,
      :log_type => EventLog::TASK_WORK_ADDED
    })
    worklog.comment = true if sheet.body and sheet.body.length > 0
    worklog.save
  end

  def close_task(user, params={})
    old_status = self.status_type
    self.completed_at = Time.now.utc
    self.status = EventLog::TASK_COMPLETED

    if self.next_repeat_date != nil
      self.save
      self.reload
      self.repeat_task
    end

    self.updated_by_id = user.id
    self.save

    params = {:body => "- <strong>Status</strong>: #{old_status} -> #{self.status_type}\n",
      :started_at => Time.now.utc,
        :duration => 0,
        :paused_duration => 0,
    }.merge(params)

    worklog = WorkLog.create_for_task(self, user, "", params)
    worklog.save

    #deliver emails
    recipients = self.notification_email_addresses(user)
    if recipients.length > 0
      begin
        Notifications::deliver_changed(:closed, self, user, recipients, params[:comment] || "")
        Worklog.create_for_task(self, user, _("Notification emails sent to") +" %s", recipients.join(", "))
      rescue
      end
    end
  end

  def open_task(user, params={})
    old_status = self.status_type
    self.update_attributes({:status => 0,
                           :completed_at => nil,
                           :updated_by => user,
    })

    params = {:body => "- <strong>Status</strong>: #{old_status} -> #{self.status_type}\n",
      :log_type => EventLog::TASK_REVERTED,
        :started_at => Time.now.utc,
    }.merge(params)

      worklog = WorkLog.create_for_task(self, user, "", params)
      worklog.save

      #deliver emails
      recipients = self.notification_email_addresses(user)
      if recipients.length > 0
        begin
          Notifications::deliver_changed(:reverted, self, user, recipients, params[:comment] || "")
          Worklog.create_for_task(self, user, _("Notification emails sent to %s", recipients.join(", ")))
        rescue
        end
      end
      project.all_notice_groups.each { |ng| ng.send_task_notice(self, user, :reverted) }
  end

  def self.create_for_user(user, project, params={})
    params = {:project => project, :company => project.company, :creator => user, :updated_by_id => user.id, :duration => 0, :description => ""}.merge(params)
    params[:due_at] = TimeParser.datetime_from_format(params[:due_at], user.date_format) if params[:due_at].is_a? String
    params[:duration] = TimeParser.parse_time(user, params[:duration], true) if params[:duration].is_a? String
    task = Task.new(params)
    task.set_task_num(user.company_id)
    result = task.save
    return result unless result
    task.users << user

    WorkLog.create_for_task(task, user, params[:comment] || "")

    #deliver emails
    recipients = task.notification_email_addresses(user)
    if recipients.length > 0
      begin
        Notifications::deliver_created(task, user, recipients, params[:comment] || "")
        Worklog.create_for_task(task, user, _("Notification emails sent to %s", recipients.join(", ")))
      rescue
      end
    end
    project.all_notice_groups.each { |ng| ng.send_task_notice(task, user) }

    return task
  end

end

# == Schema Information
#
# Table name: tasks
#
#  id                 :integer(4)      not null, primary key
#  name               :string(200)     default(""), not null
#  project_id         :integer(4)      default(0), not null
#  position           :integer(4)      default(0), not null
#  created_at         :datetime        not null
#  due_at             :datetime
#  updated_at         :datetime        not null
#  completed_at       :datetime
#  duration           :integer(4)      default(1)
#  hidden             :integer(4)      default(0)
#  milestone_id       :integer(4)
#  description        :text
#  company_id         :integer(4)
#  priority           :integer(4)      default(0)
#  updated_by_id      :integer(4)
#  severity_id        :integer(4)      default(0)
#  type_id            :integer(4)      default(0)
#  task_num           :integer(4)      default(0)
#  status             :integer(4)      default(0)
#  requested_by       :string(255)
#  creator_id         :integer(4)
#  notify_emails      :string(255)
#  repeat             :string(255)
#  hide_until         :datetime
#  scheduled_at       :datetime
#  scheduled_duration :integer(4)
#  scheduled          :boolean(1)      default(FALSE)
#  worked_minutes     :integer(4)      default(0)
#

