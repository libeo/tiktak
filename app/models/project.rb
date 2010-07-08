# A logical grouping of milestones and tasks, belonging to a Customer / Client

class Project < ActiveRecord::Base
  belongs_to    :company
  belongs_to    :customer
  belongs_to    :owner, :class_name => "User", :foreign_key => "user_id"

  has_many      :users, :through => :project_permissions
  has_many      :project_permissions, :dependent => :destroy
  has_many      :pages, :dependent => :destroy
  has_many      :tasks
  has_many      :sheets
  has_many      :work_logs, :dependent => :destroy
  has_many      :project_files, :dependent => :destroy
  has_many      :project_folders, :dependent => :destroy
  has_many      :milestones, :dependent => :destroy, :order => "due_at asc, lower(name) asc"
  has_many      :forums, :dependent => :destroy
  has_many      :shout_channels, :dependent => :destroy
  has_and_belongs_to_many :notice_groups

  named_scope :open, :conditions => "completed_at is null"
  named_scope :closed, :conditions => "completed_at is not null"
  named_scope :can, Proc.new { |perm|
    conds = []
    perms = ['comment', 'work', 'close', 'report', 'create', 'edit', 'reassign', 'prioritize', 'milestone', 'grant']
    if perm == 'all'
      perms.each do |p|
        conds << "project_permissions.can_#{p} = true"
      end
    elsif perms.include?(perm)
      conds << "project_permissions.can_#{perm} = true"
    end
    {:conditions => conds.join(" AND "), :include => [:project_permissions]}
  }

  validates_length_of           :name,  :maximum=>200
  validates_presence_of         :name

  after_create { |r|
    if r.create_forum && r.company.show_forum
      f = Forum.new
      f.company_id = r.company_id
      f.project_id = r.id
      f.name = r.full_name
      f.save
    end
  }

  PRESET_PERMS = {
    :user => [true] * 5 + [false] * 5,
    :full => [true] * 10,
    :work => [true] * 3 + [false] * 7
  }
  
  def add_users_with_permissions(users, perms=:user)
    users = [ users ].flatten
    words = %w(comment work report create edit reassign prioritize close grant milestone).map{ |w| ('can_' + w).to_sym }
    perms = PRESET_PERMS[perms] unless perms.is_a? Array

    users.each do |user|
      pp = self.project_permissions.find(:first, :conditions => {:user_id => user.id}) ||
        self.project_permissions.build({:user_id => user.id})
      pp.update_attributes(Hash[*words.zip(perms).flatten])
    end
  end

  def self.per_page
    200
  end

  def full_name
    "#{customer.name} / #{name}"
  end

  def all_notice_groups
    return self.notice_groups | NoticeGroup.get_general_groups
  end

  def all_notice_group_emails
    emails = User.find(:all, :select => 'users.email', :conditions => ['id in (select distinct user_id from notice_groups where project_id = ?', self.id]).map { |u| u.email }
    emails = emails | NoticeGroup.get_general_emails
  end

  def to_s
    name
  end

  def to_css_name
    "#{self.name.underscore.dasherize.gsub(/[ \."',]/,'-')} #{self.customer.name.underscore.dasherize.gsub(/[ \.'",]/,'-')}"
  end

  def total_estimate
    tasks.sum(:duration).to_i
  end 

  def work_done
    tasks.sum(:worked_minutes).to_i
  end 

  def overtime
    tasks.sum('worked_minutes - duration', :conditions => "worked_minutes > duration").to_i
  end

  def total_tasks_count
    if self.total_tasks.nil?
       self.total_tasks = tasks.count
       self.save
    end
    total_tasks
  end

  def open_tasks_count
    if self.open_tasks.nil?
       self.open_tasks = tasks.count(:conditions => ["completed_at IS NULL"])
       self.save
    end
    open_tasks
  end

  def total_milestones_count
    if self.total_milestones.nil?
       self.total_milestones = milestones.count
       self.save
    end
    total_milestones
  end

  def open_milestones_count
    if self.open_milestones.nil?
       self.open_milestones = milestones.count(:conditions => ["completed_at IS NULL"])
       self.save
    end
    open_milestones
  end

  ###
  # Updates the critical, normal and low counts for this project.
  # Also updates open and total tasks.
  ###
  def update_project_stats
    self.critical_count = tasks.count(:conditions => { "task_property_values.property_value_id" => company.critical_values },
                                      :include => :task_property_values)
    self.normal_count = tasks.count(:conditions => { "task_property_values.property_value_id" => company.normal_values },
                                    :include => :task_property_values)
    self.low_count = tasks.count(:conditions => { "task_property_values.property_value_id" => company.low_values },
                                 :include => :task_property_values)

    self.open_tasks = nil
    self.total_tasks = nil
  end
  

end
