require "active_record_extensions"

# A task
#
# Belongs to a project, milestone, creator
# Has many tags, users (through assignments), tags (through task_tags),
#   dependencies (tasks which should be done before this one) and 
#   dependants (tasks which should be done after this one),
#   todos, and sheets
#
class Task < ActiveRecord::Base

  include Misc

  belongs_to    :company
  belongs_to    :project
  belongs_to    :milestone

  #has_many      :users, :through => :task_owners, :source => :user
  #has_many      :task_owners, :dependent => :destroy
  #has_many      :notifications, :dependent => :destroy
  #has_many      :watchers, :through => :notifications, :source => :user

  augment AssignmentsNew

  has_many      :work_logs, :order => "started_at asc"
  has_many      :attachments, :class_name => "ProjectFile", :dependent => :destroy

  belongs_to    :creator, :class_name => "User", :foreign_key => "creator_id"
  belongs_to    :old_owner, :class_name => "User", :foreign_key => "user_id"

  has_and_belongs_to_many  :tags, :join_table => 'task_tags'
  has_and_belongs_to_many  :dependencies, :class_name => "Task", :join_table => "dependencies", :association_foreign_key => "dependency_id", :foreign_key => "task_id", :order => 'dependency_id', :after_add => :mark_new_dependency, :after_remove => :mark_removed_dependency
  has_and_belongs_to_many  :dependants, :class_name => "Task", :join_table => "dependencies", :association_foreign_key => "task_id", :foreign_key => "dependency_id", :order => 'task_id', :after_add => :mark_new_dependant, :after_remove=> :mark_removed_dependant

  has_many :task_property_values, :dependent => :destroy, :include => [ :property ]
  has_many :task_customers, :dependent => :destroy
  has_many :customers, :through => :task_customers, :order => "customers.name asc"
  adds_and_removes_using_params :customers

  has_one       :ical_entry
  belongs_to :updated_by, :class_name => "User"

  has_many      :todos, :order => "completed_at IS NULL desc, completed_at desc, position"
  has_many      :sheets
  has_and_belongs_to_many :resources

  accepts_nested_attributes_for :task_property_values
  accepts_nested_attributes_for :assignments
  accepts_nested_attributes_for :work_logs
  accepts_nested_attributes_for :attachments
  accepts_nested_attributes_for :dependencies
  accepts_nested_attributes_for :dependants
  accepts_nested_attributes_for :todos

  attr_reader :new_assignments

  augment RepeatDate
  augment Attributes
  augment Tags
  augment TaskProperties
  augment ViewHelpers

  validates_length_of           :name,  :maximum=>200, :allow_nil => true
  validates_presence_of         :name

  validates_presence_of		:company
  validates_presence_of		:project
  validates_presence_of   :updated_by_id
  validates_presence_of   :creator_id
  validates_presence_of   :description

  before_create :set_task_num

  after_save :save_callback

  after_create :create_callback
  after_update :update_callback

  private

  def mark_new_dependency(dependency)
    @new_dependencies ||= []
    @new_dependencies << dependency
  end

  def mark_removed_dependency(dependency)
    @removed_dependencies ||= []
    @removed_dependencies << dependency
  end

  def mark_new_dependant(dependant)
    @new_dependants ||= []
    @new_dependants << dependant
  end

  def mark_removed_dependant(dependant)
    @removed_dependants ||= []
    @removed_dependants << dependant
  end

  #Called on EXISTING and NEW records
  def save_callback
    self.ical_entry.destroy if self.ical_entry

    project = self.project
    project.update_project_stats
    project.save

    self.milestone.update_counts if self.milestone

    if self.status >= 2
      self.completed_at = Time.now.utc
    elsif self.status < 2 and self.completed_at
      self.completed_at = nil
    end

    next_repeat = self.next_repeat_date
    self.repeat_task if next_repeat and Time.now.utc >= next_repeat
  end

  #Called on EXISTING records
  def update_callback

    send_notifications

  end

  def send_notifications
    debugger
    if self.has_changed?
      worklog, event_type = self.create_event_worklog
      self.deliver_notification_emails(self.updated_by, worklog, event_type)
      @new_assignments, @removed_assignments, @new_dependencies, @removed_dependencies, @new_dependants, @removed_dependants = [nil] * 6
    end
  end

  #Called on NEW records
  def create_callback
    debugger
    if self.recipient_users.length > 0
      begin
        Notifications::deliver_created(self, self.creator, self.all_notify_emails, (self.work_logs.first and self.work_logs.first.comment? ? self.work_logs.first.body : "") )
        self.notified_last_change.set(self.recipient_users)
        self.mark_as_unread(self.recipient_users)

        worklog = Worklog.create_for_task(self, self.creator, {:body => _("Notification emails sent to %s", self.recipient_users.map{|r|r.name}.join(", "))})
        worklog.users = self.recipient_users
        worklog.save
      rescue
      end
    end
    self.project.all_notice_groups.each { |ng| ng.send_task_notice(self, self.creator) }
  end

  public

  def has_changed?
    self.changed? or 
    self.assignments.select { |a| a.changed? or a.new_record? }.length > 0
    !@new_assignments.nil? or
    !@removed_assignments.nil? or
    !@new_dependencies.nil? or 
    !@removed_dependencies.nil? or
    !@new_dependants.nil? or 
    !@removed_dependants.nil?
  end

  def deliver_notification_emails(user, worklog, event_type=:updated)
    if self.recipient_users.length > 0
      begin
        body = worklog.comment? ? worklog.body.gsub(/<[^>]*>/, '') : ''
        Notifications::deliver_changed(event_type, self, user, self.all_notify_emails, body)
        self.notified_last_change = self.recipient_users
        self.mark_as_unread(self.recipient_users)

        worklog = Worklog.create_for_task(self, user, {:body => _("Notification emails sent to %s", self.recipient_users.map{|r|r.name}.join(", "))})
        worklog.users = self.recipient_users
        worklog.save
      rescue
      end
    end
    #self.project.all_notice_groups.each { |ng| ng.send_task_notice(self, user) }
  end

  def create_event_worklog
    event_type = :updated
    body = []

    #Scan all changed attributes and create a message indicating what changed
    self.changes do |attr, values|
      case attr
      when 'project_id'
        body << "Project: #{self.project_was.name} -> #{self.project.name}"
      when 'duration'
        body << "Estimate: #{self.updated_by.format_duration(values.first)} -> #{self.updated_by.format_duration(values.last)}"
      when 'milestone_id'
        before = self.milestone_was ? self.milestone_was.name : 'none'
        after = self.milestone ? self.milestone.name : 'none'
        body << "Milestone: #{before} -> #{after}"
      when 'due_at'
        before = self.due_at_was ? self.updated_by.tz.utc_to_local(values.first).strftime_localized("%A, %d %B %Y") : 'none'
        after = self.due_at ? self.updated_by.tz.utc_to_local(values.last).strftime_localized("%A, %d %B %Y") : 'none'
        body << "Due: #{before} -> #{after}"
      when 'status'
        body << "Status: #{self.status_types[values.first]} -> #{self.status_types[values.last]}"
      else
        body << "#{attr.capitalize}: #{values.first} -> #{values.last}"
      end
    end

    #Special cases
    if self.assignments.select { |a| (a.new_record? or a.changed?) and a.assigned? }.length > 0 or @new_assignments or @removed_assignments
      body << "Assignments: #{self.assignments.select { |a| a.assigned? }.length > 0 ? self.assignments.select { |a| a.assigned? }.map { |a| a.user.name }.join(', ') : 'None'}"
      event_type = :reassigned
    end

    if self.dependencies.select { |d| d.changed?  or d.new_record? }.length > 0 or @new_dependencies or @removed_dependencies
      body << "Dependencies: #{self.dependencies.length > 0 ? self.dependencies.map { |d| d.name }.join(', ') : 'None'}"
    end

    #Since work logs will soon be nested into tasks, work_logs are saved before the task.
    #Thus, if the user just added a comment, it should be the last work log added to the task
    if body.length == 0 and self.work_logs.last.comment?
      body = [self.work_logs.last.comment]
      update_type = :comment
    end

    #Create event work log only if something was modified. Body contais a list of things that have been modified
    worklog = nil
    if body.length > 0

      defaults = {
        :log_type => EventLog::TASK_MODIFIED,
        :body => body.join("\n")
      }
      worklog = WorkLog.create_for_task(self, self.updated_by, defaults)
      if self.status_changed?
        if self.status < 2
          worklog.log_type = EventLog::TASK_REVERTED
          update_type = :reverted
        else
          worklog.log_type = EventLog::TASK_COMPLETED
          update_type = :completed
        end
      end

    end

    return worklog, event_type
  end

  def self.per_page
    25
  end

  def recalculate_worked_minutes
    self.worked_minutes = WorkLog.sum(:duration, :conditions => ["task_id = ?", self.id]).to_i / 60
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
    params.merge!(:user => user,
      :customer => (self.customers.first || self.project.customer))
    WorkLog.create_for_user(user, params)
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
    self.save
  end

  def close_task(user, params={})
    if self.status < 2
      self.status = EventLog::TASK_COMPLETED
      self.updated_by_id = user.id
      self.save
    end
  end

  def open_task(user, params={})
    if self.status >= 2
      self.status = EventLog::TASK_REVERTED
      self.updated_by_id = user.id
      self.save
    end
  end

  def self.create_for_user(user, project, params={})
    params = {:project => project, :company => project.company, :creator => user, :updated_by_id => user.id, :duration => 0, :description => ""}.merge(params)
    params[:due_at] = TimeParser.datetime_from_format(params[:due_at], user.date_format) if params[:due_at].is_a? String
    params[:duration] = TimeParser.parse_time(user, params[:duration], true) if params[:duration].is_a? String
    Task.create(params)
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

