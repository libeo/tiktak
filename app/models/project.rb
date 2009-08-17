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

  def full_name
    "#{customer.name} / #{name}"
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
    # This method doesn't really make sense now we've removed default
    # sorting, and requiring severity and priority. If I am going to leave
    # it for now, but if this hasn't been uncommented by Oct 2009, feel
    # free to remove this method, all calls to it, and the critical, normal
    # and low columns in project. BW. 17/08/09

    # self.critical_count = tasks.select { |t| t.critical? }.length
    # self.normal_count = tasks.select { |t| t.normal? }.length
    # self.low_count = tasks.select { |t| t.low? }.length
    # self.open_tasks = nil
    # self.total_tasks = nil
  end
  

end
