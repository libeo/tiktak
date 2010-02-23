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
  named_scope :visible, :conditions => { :system => false }

  before_create :set_company_from_user

  OTHERS = ["NoUser"]

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

  # Returns an array of all tasks matching the conditions from this filter
  # if extra_conditions is passed, that will be ANDed to the conditions
  def tasks(extra_conditions = nil, selected=nil)
    conds = conditions(extra_conditions)
    order = "tasks.id desc"
    
    if selected
      return Task.find(:all, :conditions => conds,
                       :select => selected,
                       :joins => get_includes(selected),
                       :order => order
                      )
    else
      return Task.find(:all, :conditions => conditions(extra_conditions), 
                                  :order => order,
                                  :include => to_include
                      )
    end
  end

  def tasks_paginated(extra_conditions=nil, options={})
    options = {:page => 1, :order => "tasks.name asc"}.merge(options)

    return Task.paginate(:page => options[:page],
                          :conditions => conditions(extra_conditions), 
                          :order => options[:order],
                          #:include => options[:select] ? get_includes(options[:select]) : to_include,
                          :include => to_include + [:task_property_values],
                          :select => options[:select]
                        )
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
  # unassigned tasks and unread tasks are counted.
  # The value will be cached and re-used unless force_recount is passed.
  def display_count(user, force_recount = false)
    @display_count = nil if force_recount

    count_conditions = []
    count_conditions << "(task_owners.unread = 1 and task_owners.user_id = #{ user.id })" 
    count_conditions << "(task_owners.id is null)"

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
    res << extra_conditions if extra_conditions

    if user.projects.any?
      sql = "tasks.project_id in (select project_id from project_permissions where user_id = #{user.id}) or task_owners.user_id = #{user.id}"
      #project_ids = user.projects.map { |p| p.id }.join(",")
      #sql = "tasks.project_id in (#{ project_ids })"
      #sql += " or task_owners.user_id = #{ user.id }"
      res << "(#{ sql })"
    else
      res << "(task_owners.user_id = #{ user.id })"
    end

    res << ["tasks.company_id = #{user.company_id}", "projects.completed_at IS NULL"]

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
      sql = "work_logs.project_id in (select project_id from project_permissions where user_id = #{user.id}) or work_logs.user_id = #{user.id}"
      #project_ids = user.projects.map { |p| p.id }.join(",")
      #sql = "work_logs.project_id in (#{ project_ids })"
      #sql += " or work_logs.user_id = #{ user.id }"
      res << "(#{ sql })"
    else
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

  #def work_log_to_include
  #  to_include = [:project, :user, :customer,
  #    {:company => :properties },
  #    {:task => [:tags, :sheets, :todos, :dependencies, :milestone, :notifications, :watchers, :task_property_values]},
  #  ]
  #  return to_include
  #end

  def work_log_to_include
    to_include = [:project, :user, :customer, {:task => [:task_property_values]} ,
      {:company => :properties },
    ]
    return to_include
  end
  
  def to_include
    to_include = [ :users, :tags, :sheets, :todos, :dependencies, 
                   :milestone, :notifications, :watchers, 
                   :customers, :task_property_values ]
    to_include << { :company => :properties }
    to_include << { :project => :customer }
  end
  
  #def get_includes(fields)
  #  conds = [ ['task_owners', 'task_owners.task_id', 'tasks.id'] ]

  # 
  #  fields = fields.split(/\s+/).map{ |i| i.split('.').first }.uniq.sort
  #  fields << "customers" if fields.include? "projects" and not fields.include? "customers"
  #  fields = fields.insert(0,"companies") if fields.include? "property_values" and not fields.include? "companies"
  #  debugger
  #  fields.each do |field|
  #    case field
  #      when 'users' then
  #        conds << ['users', 'task_owners.user_id', 'users.id']
  #        #conds << ['task_owners', 'task_owners.task_id', 'tasks.id']
  #      when 'tags' then
  #        conds << ['tags', 'task_tags.tag_id', 'tags.id']
  #        conds << ['task_tags', 'task_tags.id', 'tags.id']
  #      when 'sheets' then
  #        conds << ['sheets', 'sheets.task_id', 'tasks.id']
  #      when 'todos' then
  #        conds << ['todos', 'todos.task.id', 'tasks.id']
  #      when 'dependencies' then
  #        conds << ['dependencies', 'dependencies.task_id', 'tasks.id']
  #        conds << ['dependencies', 'dependencies.dependency_id', 'tasks.id']
  #      when 'milestones' then
  #        conds << ['milestones', 'tasks.milestone_id', 'milestones.id']
  #      when 'notifications' then
  #        conds << ['notifications', 'task_notifications.notification_id', 'notifications.id']
  #        conds << ['task_notifications', 'task_notifications.task_id', 'tasks.id']
  #        #TODO: check watchers
  #      when 'customers' then
  #        conds << ['task_customers', 'task_customers.task_id', 'tasks.id']
  #        conds << ['customers', 'task_customers.customer_id', 'customers.id']
  #      when 'property_values' then
  #        conds << ['properties', 'properties.company_id', 'companies.id']
  #        conds << ['property_values', 'property_values.property_id', 'properties.id']
  #      when 'companies' then
  #        conds << ['companies', 'companies.id', 'tasks.company_id']
  #      when 'projects' then
  #        conds << ['projects', 'projects.id', 'tasks.project_id']
  #    end
  #  end

  #  return conds.map { |c| "left outer join #{c[0]} on #{c[1]}=#{c[2]}" }.join(" ")
  #end

  def get_includes(fields)
   
    debugger
    singular = %w(sheets todos milestones)
    special = {'companies' => { :company => :properties}, 'projects' => {:project => :customer}}

    fields = fields.split(/\s+/).map{ |i| i.split('.').first}.uniq.select { |f| f != 'tasks' }

    fields = fields.map do |f|
      if singular.include? f
        f = f[0, f.length-1]
      elsif special[f]
        f = special[f]
      end
      f
    end
    fields.delete "customers"

    return fields
  end

  def set_company_from_user
    self.company = user.company
  end

  def conditions_for_other_qualifiers(qualifiers)
    res = []
    qualifiers.each do |q|
      case q.qualifiable_type
        when 'NoUser'
          res << "tasks.id not in (select task_owners.task_id from task_owners)"
        when 'NoCreator'
          res << 'tasks.creator_id not in (select task_owners.user_id from task_owners)'
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
      return "task_owners.user_id"
    elsif class_type == "Project"
      return "tasks.project_id"
    elsif class_type == "Customer"
      return "projects.customer_id"
    elsif class_type == "Company"
      return "tasks.company_id"
    elsif class_type == "Milestone"
      return "tasks.milestone_id"
    elsif class_type == "Tag"
      return "task_tags.tag_id"
    elsif class_type == "Creator"
      return "tasks.creator_id"
    else
      return "#{ class_type.downcase }_id"
    end
  end

  def work_log_column_name_for(class_type)
    if class_type == "User"
      return "work_logs.user_id"
    elsif class_type == "Project"
      return "work_logs.project_id"
    elsif class_type == "Customer"
      return "work_logs.customer_id"
    elsif class_type == "Company"
      return "work_logs.company_id"
    elsif class_type == "Milestone"
      return "tasks.milestone_id"
    elsif class_type == "Tag"
      return "task_tags.tag_id"
    else
      return "#{ class_type.downcase }_id"
    end
  end
  
end
