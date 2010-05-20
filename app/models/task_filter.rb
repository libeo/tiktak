###
# A task filter is used to find tasks matching the filters set up
# in session.
###
class TaskFilter < ActiveRecord::Base
  belongs_to :user
  belongs_to :company
  has_many(:qualifiers, :dependent => :destroy, :class_name => "TaskFilterQualifier")
  accepts_nested_attributes_for :qualifiers

  has_many :keywords, :dependent => :destroy

  validates_presence_of :user
  validates_presence_of :name

  named_scope :shared, :conditions => { :shared => true }
  #named_scope :visible, :conditions => { :system => false }
  named_scope :visible, :conditions => "task_filters.system = false and task_filters.name != 'shortlist'"

  before_create :set_company_from_user

  OTHERS = ['NoUser', 'CreatorNoAssignment', 'TaskNumber']

  # Returns the system filter for the given user. If none is found, 
  # create and saves a new one and returns that.
  def self.system_filter(user)
    filter = user.task_filters.first(:conditions =>["system = true and name != 'shortlist'"])
    if filter.nil?
      filter = user.task_filters.build(:name => "System filter for #{ user }", 
                                       :user_id => user.id, :system => true)
      filter.save!
    end

    return filter
  end

  def merge_options(options, conditions)
    options.delete :conditions
    options = {:order => "tasks.id desc",
      :conditions => conditions,
    }.merge(options)

    options[:include] ||= get_includes(options[:select]) || to_include
    return options
  end

  # Returns an array of all tasks matching the conditions from this filter
  # if extra_conditions is passed, that will be ANDed to the conditions
  def tasks(extra_conditions = nil, options={})
    return Task.find(:all, merge_options(options, conditions(extra_conditions)))
  end

  def tasks_paginated(extra_conditions=nil, options={})
    return Task.paginate(merge_options(options, conditions(extra_conditions)))
  end

  # Returns the count of tasks matching the conditions of this filter.
  # if extra_conditions is passed, that will be ANDed to the conditions
  def count(extra_conditions = nil)
    #user.company.tasks.count(:conditions => conditions(extra_conditions),
    #                         :include => to_include)
    Task.count(:conditions => conditions(extra_conditions),
               :include => to_include)
  end

  def work_logs(extra_conditions = nil, limit = nil)
    return WorkLog.find(:all, :conditions => work_logs_conditions(extra_conditions),
                        :order => "work_logs.started_at asc",
                        :include => work_log_to_include,
                        :limit => limit)
  end

  def work_logs_paginated(extra_conditions = nil, page = 1)
    return WorkLog.paginate(:page => page, :conditions => work_logs_conditions(extra_conditions),
                            :order => "work_logs.started_at asc",
                            :include => work_log_to_include)
  end

  def work_log_count(extra_conditions = nil)
    return WorkLog.count(:conditions => work_logs_conditions(extra_conditions),
                         :include => work_log_to_include
                        )
  end

  # Returns a count to display for this filter. The count represents the
  # number of tasks that look they need attention for the given user - 
  # unassigned tasks are counted
  # The value will be cached and re-used unless force_recount is passed.
  def display_count(user, force_recount = false)
    @display_count = nil if force_recount

    count_conditions = []
    count_conditions << "(assignments.user_id = #{ user.id })" 
    count_conditions << "(assignments.id is null)"

    sql = count_conditions.join(" or ")
    sql = "(#{ sql })"
    @display_count ||= count(sql)
  end

  # Returns an array of the conditions to use for a sql lookup
  # of tasks for this filter
  def conditions(extra_conditions = nil)

    status_qualifiers = qualifiers.select { |q| q.qualifiable_type == "Status" }
    property_qualifiers = qualifiers.select { |q| q.qualifiable_type == "PropertyValue" }
    other_qualifiers = qualifiers.select { |q| TaskFilter::OTHERS.include?(q.qualifiable_type ) }
    standard_qualifiers = qualifiers - property_qualifiers - status_qualifiers - other_qualifiers

    res = conditions_for_standard_qualifiers(standard_qualifiers)
    res += conditions_for_property_qualifiers(property_qualifiers)
    res << conditions_for_status_qualifiers(status_qualifiers)
    res << conditions_for_other_qualifiers(other_qualifiers) if other_qualifiers.length > 0
    res << conditions_for_keywords
    res << extra_conditions if extra_conditions and extra_conditions.length > 0

    if user.projects.any?
      #Select tasks where user has been assigned to the project or user has been assigned to the task
      sql = "tasks.project_id in (select project_id from project_permissions where user_id = #{user.id}) or users.id = #{user.id}"
      res << "(#{ sql })"
    else
      #Select tasks where user has been assigned to the task
      res << "(users.id = #{ user.id })"
    end

    # I don't think we need to include a condition to check against the company since a project does not belong to many companies
    #res << ["tasks.company_id = #{user.company_id}", "projects.completed_at IS NULL"]
    res << ["projects.completed_at IS NULL"]

    res = res.select { |c| !c.blank? }
    res = res.join(" AND ")

    return res
  end

  def work_logs_conditions(extra_conditions = nil)
    status_qualifiers = qualifiers.select { |q| q.qualifiable_type == "Status" }
    property_qualifiers = qualifiers.select { |q| q.qualifiable_type == "PropertyValue" }
    other_qualifiers = qualifiers.select { |q| TaskFilter::OTHERS.include?(q.qualifiable_type ) }
    standard_qualifiers = qualifiers - property_qualifiers - status_qualifiers - other_qualifiers

    res = conditions_for_standard_qualifiers(standard_qualifiers, true)
    res += conditions_for_property_qualifiers(property_qualifiers)
    res << conditions_for_status_qualifiers(status_qualifiers)
    res << conditions_for_other_qualifiers(other_qualifiers) if other_qualifiers.length > 0
    res << conditions_for_keywords
    res << extra_conditions if extra_conditions

    if user.projects.any?
      #Select work logs where user has been assigned to the project or user has been assigned to the task
      sql = "work_logs.project_id in (select project_id from project_permissions where user_id = #{user.id}) or work_logs.user_id = #{user.id}"
      res << "(#{ sql })"
    else
      #Select work logs created by user
      res << "(work_logs.user_id = #{ user.id })"
    end

    res << ["work_logs.company_id = #{user.company_id}" ] 

    res = res.compact.join(" AND ")

    return res
  end

  # Sets the keywords for this filter using the given array
  def keywords_attributes=(new_keywords)
    keywords.clear

    (new_keywords || []).each do |word|
      keywords.build(:word => word)
    end
  end

  private

  def work_log_to_include
    includes = [:project, :user, :customer, {:task => [:task_property_values]} ,
      {:company => :properties },
    ]
    return includes
  end

  def to_include
    to_include = [ :sheets, :todos, :dependencies, :assigned_users,
      :milestone, :assignments, 
      :customers, :task_property_values ]
    to_include << { :company => :properties }
    to_include << { :project => :customer }
  end

  def get_includes(fields)
    return nil unless fields

    singular = %w(sheets milestones)
    special = {'companies' => { :company => :properties}, 
      'customers_projects' => {:project => :customer}, 
      'dependencies_tasks' => :dependencies,
      'task_property_values' => {:task_property_values => [:property_value, :property]},
      'users' => :assigned_users
    }

    fields = fields.split(/\s+/).map{ |i| i.split('.').first}.uniq.select { |f| f and f != 'tasks' }
    fields.delete 'projects' if fields.include? 'customers_projects'
    fields.delete 'property_values' if fields.include? 'task_property_values'
    fields.delete 'assigned_users' if fields.include? 'users'

    fields = fields.map do |f|
      if singular.include? f
        f = f[0, f.length-1]
      elsif special[f]
        f = special[f]
      end
      f
    end

    return fields.uniq
  end

  def set_company_from_user
    self.company = user.company
  end

  def conditions_for_other_qualifiers(qualifiers)
    res = []

    cna = qualifiers.select { |q| q.qualifiable_type == 'CreatorNoAssignment' }
    if cna.length > 0
      res << "tasks.creator_id IN (#{cna.map{ |c| c.qualifiable.id }.join(',')})"
      res << "tasks.id not in (select assignments.task_id from assignments)"
    end

    qualifiers.each do |q|
      case q.qualifiable_type
      when 'NoUser'
        res << "tasks.id not in (select assignments.task_id from assignments)"
      when 'TaskNumber'
        res << "tasks.task_num = #{q.qualifiable_id}"
      end
    end

    res = res.length > 0 ? res.join(" AND ") : ""
    return res
  end

  # Returns a conditions hash the will filter tasks based on the
  # given property value qualifiers
  def conditions_for_property_qualifiers(property_qualifiers)
    name = "task_property_values.property_value_id"
    grouped = property_qualifiers.group_by { |q| q.qualifiable.property }

    res = []
    grouped.each do |property, qualifiers|
      ids = qualifiers.map { |q| q.qualifiable.id }
      res << "#{ name } IN (#{ ids.join(", ") })"
    end

    return res
  end

  # Returns an array of conditions that will filter tasks based on the
  # given standard qualifiers.
  # Standard qualifiers are things like project, milestone, user, where
  # a filter will OR the different users, but and between different types
  def conditions_for_standard_qualifiers(standard_qualifiers, work_logs = false)
    res = []

    grouped_conditions = standard_qualifiers.group_by { |q| q.qualifiable_type }
    grouped_conditions.each do |type, values|
      if work_logs
        name = work_log_column_name_for(type)
      else
        name = column_name_for(type)
      end
      ids = values.map { |v| v.qualifiable_id }
      res << "#{ name } in (#{ ids.join(",") })"
    end

    return res
  end

  # Returns a string sql fragment that will limit tasks to 
  # those that match the set keywords
  def conditions_for_keywords
    res = []

    keywords.each do |kw|
      str = "lower(tasks.name) like '%#{ kw.word.downcase }%'"
      str += " or lower(tasks.description) like '%#{ kw.word.downcase }%'"
      res << str
    end

    res = res.join(" or ")
    return "(#{ res })" if !res.blank?
  end

  # Returns a sql string fragment that will limit tasks to only
  # status set by the status qualifiers.
  # Status qualifiers have to be handled especially until the
  # migration from an array in code to db backed statuses is complete
  def conditions_for_status_qualifiers(status_qualifiers)
    old_status_ids = []
    c = company || user.company

    status_qualifiers.each do |q|
      status = q.qualifiable
      old_status = c.statuses.index(status)
      old_status_ids << old_status
    end

    old_status_ids = old_status_ids.join(",")
    return "tasks.status in (#{ old_status_ids })" if !old_status_ids.blank?
  end


  # Returns the column name to use for lookup for the given
  # class_type
  def column_name_for(class_type)
    if class_type == "User"
      return "assignments.user_id"
    elsif class_type == 'Creator'
      return 'tasks.creator_id'
    elsif class_type == "Project"
      return "tasks.project_id"
    elsif class_type == "Customer"
      return "projects.customer_id"
    elsif class_type == "Company"
      return "tasks.company_id"
    elsif class_type == "Milestone"
      return "tasks.milestone_id"
    elsif class_type == "Creator"
      return "tasks.creator_id"
    elsif class_type == 'Client'
      return "projects.customer_id"
    else
      return "#{ class_type.downcase }_id"
    end
  end

  def work_log_column_name_for(class_type)
    if class_type == "User"
      return "work_logs.user_id"
    elsif class_type == 'Creator'
      return 'tasks.creator_id'
    elsif class_type == "Project"
      return "work_logs.project_id"
    elsif class_type == "Customer"
      return "work_logs.customer_id"
    elsif class_type == 'Client'
      return 'work_logs.customer_id'
    elsif class_type == "Company"
      return "work_logs.company_id"
    elsif class_type == "Milestone"
      return "tasks.milestone_id"
    else
      return "#{ class_type.downcase }_id"
    end
  end

end
