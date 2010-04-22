# A work entry, belonging to a user & task
# Has a duration in seconds for work entries

class WorkLog < ActiveRecord::Base
  has_many(:custom_attribute_values, :as => :attributable, :dependent => :destroy, 
           # set validate = false because validate method is over-ridden and does that for us
           :validate => false)
  include CustomAttributeMethods

  belongs_to :user
  belongs_to :company
  belongs_to :project
  belongs_to :customer
  belongs_to :task
  belongs_to :scm_changeset

  has_one    :ical_entry, :dependent => :destroy
  has_one    :event_log, :as => :target, :dependent => :destroy
  has_many    :work_log_notifications, :dependent => :destroy
  has_many    :users, :through => :work_log_notifications

  validates_presence_of :task_id
  
  after_update { |r|
    r.ical_entry.destroy if r.ical_entry
    l = r.event_log
    l.created_at = r.started_at
    l.save
    
    #UGLY HACK : I don't know why yet that logs are created and sometimes don't have the same reference to the project as their task
    #update : I suspect that it might have been in the old version when you created a work_log at the same time as you changed the project of a task
    r.project = r.task.project if r.task and r.project != r.task.project

    if r.task && r.duration.to_i > 0
      r.task.recalculate_worked_minutes
      r.task.save
    end
  
  }

  before_create do |worklog|
    worklog.started_at = Time.now.utc unless worklog.started_at
    worklog.project_id = worklog.task.project_id unless worklog.project_id
    worklog.company_id = worklog.task.company_id unless worklog.company_id
  end

  after_create { |r|
    l = r.create_event_log
    l.company_id = r.company_id
    l.project_id = r.project_id
    l.user_id = r.user_id
    l.event_type = r.log_type
    l.created_at = r.started_at
    l.save

    
    if r.task && r.duration.to_i > 0
      r.task.recalculate_worked_minutes
      r.task.save
    end
    
  }

  after_destroy { |r|
    if r.task
      r.task.recalculate_worked_minutes
      r.task.save
    end
  
  }

  #validates_each :started_at, :on => :update do |model, attr, value|
  #  if value < Time.now - (60 * 60 * 24)
  #    model.errors.add attr, "Cannot modify a work log 24 hours after creation"
  #  end
  #end

  def self.per_page
    40
  end

  ###
  # Creates and saves a worklog for the given task.
  # If comment is given, it will be escaped before saving.
  # The newly created worklog is returned. 
  ###
  def self.create_for_task(task, user, params={})
    defaults = {:user => user,
      :task => task,
      :project => task.project,
      :company => task.project.company,
      :customer => task.project.customer,
      :duration => 0,
      :started_at => Time.now.utc}

    params[:duration] = TimeParser.parse_time(user, params[:duration]) if params[:duration].is_a? String
    params[:started_at] = TimeParser.parse_time(user, params[:started_at]) if params[:started_at].is_a? String

    params = defaults.merge(params)

    if params[:body]
      params[:body] = CGI::escapeHTML(params[:body])
      params[:comment] = true
    end

    WorkLog.new(params)
  end
    
  
  ###
  # Creates and saves a worklog for the given task.
  # If comment is given, it will be escaped before saving.
  # The newly created worklog is returned. 
  ###
  #def self.create_for_task(task, user, comment, params={})
  #  params = {:log_type => EventLog::TASK_CREATED}.merge(params)
  #  worklog = WorkLog.new(params)
  #  worklog.user = user
  #  worklog.company = task.project.company
  #  worklog.customer = task.project.customer
  #  worklog.project = task.project
  #  worklog.task = task
  #  worklog.started_at = Time.now.utc
  #  worklog.duration = 0

  #  if !comment.blank?
  #    worklog.body =  CGI::escapeHTML(comment)
  #    worklog.comment = true
  #  end 
  #  
  #  worklog.save

  #  return worklog
  #end

  def ended_at
    self.started_at + self.duration + self.paused_duration
  end

  # Sets the associated customer using the given name
  def customer_name=(name)
    self.customer = company.customers.find_by_name(name)
  end
  # Returns the name of the associated customer
  def customer_name
    customer.name if customer
  end
end
