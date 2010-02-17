# A user from a company
require 'digest/md5'

class User < ActiveRecord::Base
  has_many(:custom_attribute_values, :as => :attributable, :dependent => :destroy, 
           # set validate = false because validate method is over-ridden and does that for us
           :validate => false)
  include CustomAttributeMethods

  belongs_to    :company
  belongs_to    :customer
  belongs_to    :default_user_permission
  has_many      :projects, :through => :project_permissions, :conditions => ['projects.completed_at IS NULL'], :order => "projects.customer_id, projects.name"
  #has_many      :projects, :through => :project_permissions, :order => "projects.customer_id, projects.name"
  has_many      :completed_projects, :through => :project_permissions, :conditions => ['projects.completed_at IS NOT NULL'], :source => :project, :order => "projects.customer_id, projects.name"
  has_many      :all_projects, :through => :project_permissions, :order => "projects.customer_id, projects.name", :source => :project
  has_many      :project_permissions, :dependent => :destroy
  has_many      :pages, :dependent => :nullify
  has_many      :tasks, :through => :task_owners
  has_many      :task_owners, :dependent => :destroy
  has_many      :work_logs, :dependent => :destroy
  has_many      :work_log_notifications, :dependent => :destroy
  has_many      :shouts, :dependent => :nullify

  has_many      :notifications, :dependent => :destroy
  has_many      :notifies, :through => :notifications, :source => :task

  has_many      :forums, :through => :moderatorships, :order => 'forums.name'
  has_many      :moderatorships, :dependent => :destroy

  has_many      :posts, :dependent => :destroy
  has_many      :topics, :dependent => :destroy

  has_many      :monitorships,:dependent => :destroy
  has_many      :monitored_topics, :through => :monitorships, :source => 'topic', :conditions => ['monitorships.active = ? AND monitorship_type = ?', true, 'topic'], :order => 'topics.replied_at desc'
  has_many      :monitored_forums, :through => :monitorships, :source => 'forum', :conditions => ['monitorships.active = ? AND monitorship_type = ?', true, 'forum'], :order => 'forums.position'

  has_many      :moderatorships, :dependent => :destroy
  has_many      :forums, :through => :moderatorships, :order => 'forums.name'

  has_many      :shout_channel_subscriptions, :dependent => :destroy
  has_many      :shout_channels, :through => :shout_channel_subscriptions, :source => :shout_channel
  has_many      :chat_messages, :through => :chats

  has_many      :widgets, :order => "widgets.column, widgets.position", :dependent => :destroy

  has_many      :chats, :conditions => ["active = 0 OR active = 1"], :dependent => :destroy
  has_many      :chat_requests, :foreign_key => 'target_id', :class_name => 'Chat', :dependent => :destroy

  has_many      :task_filters, :dependent => :destroy

  belongs_to       :default_project, :class_name => "Project", :foreign_key => :default_project_id

  has_and_belongs_to_many :notice_groups
  has_one :default_user_permission, :foreign_key => "user_id"
  
  validates_length_of           :name,  :maximum=>200, :allow_nil => true
  validates_presence_of         :name

  validates_length_of           :username,  :maximum=>200, :allow_nil => true
  validates_presence_of         :username
  validates_uniqueness_of       :username, :scope => "company_id"

  validates_length_of           :password,  :maximum=>200, :allow_nil => true
  validates_presence_of         :password

  validates_presence_of         :company

  after_destroy { |r|
    begin
      File.delete(r.avatar_path)
      File.delete(r.avatar_large_path)
    rescue
    end


    
  }

  before_create                 :generate_uuid

  after_create			:generate_widgets
  
  attr_protected :uuid, :autologin

  ###
  # Searches the users for company and returns 
  # any that have names or ids that match at least one of
  # the given strings
  ###
  def self.search(company, strings)
    conds = Search.search_conditions_for(strings, [ :name ], :start_search_only => true)
    return company.users.find(:all, :conditions => conds)
  end

  def path
    File.join("#{RAILS_ROOT}", 'store', 'avatars', self.company_id.to_s)
  end

  def avatar_path
    File.join(self.path, "#{self.id}")
  end

  def avatar_large_path
    File.join(self.path, "#{self.id}_large")
  end

  def avatar?
    File.exist? self.avatar_path
  end

  def generate_uuid
    if uuid.nil?
      self.uuid = Digest::MD5.hexdigest( rand(100000000).to_s + Time.now.to_s)
    end
    if autologin.nil?
      self.autologin = Digest::MD5.hexdigest( rand(100000000).to_s + Time.now.to_s)
    end
  end

  def new_widget
    Widget.new(:user => self, :company_id => self.company_id, :collapsed => 0, :configured => true)
  end
  
  def generate_widgets

    old_lang = Localization.lang

    Localization.lang(self.locale || 'en_US')

    w = new_widget
    w.name =  _("Top Tasks")
    w.widget_type = 0
    w.number = 5
    w.mine = true
    w.order_by = "priority"
    w.column = 0
    w.position = 0
    w.save
    
    w = new_widget
    w.name = _("Newest Tasks")
    w.widget_type = 0
    w.number = 5
    w.mine = false
    w.order_by = "date"
    w.column = 0
    w.position = 1
    w.save
    
    w = new_widget
    w.name = _("Recent Activities")
    w.widget_type = 2
    w.number = 20
    w.column = 2
    w.position = 0
    w.save
    
    w = new_widget
    w.name = _("Open Tasks")
    w.widget_type = 3
    w.number = 7
    w.mine = true
    w.column = 1
    w.position = 0
    w.save
    
    w = new_widget
    w.name = _("Projects")
    w.widget_type = 1
    w.number = 0
    w.column = 1
    w.position = 1
    w.save
    
    Localization.lang(old_lang)

  end
  
  def avatar_url(size=32, secure = false)
    if avatar?
      if size > 25 && File.exist?(avatar_large_path)
        "/users/avatar/#{self.id}?large=1&" + File.mtime(avatar_large_path).to_i.to_s
      else
        "/users/avatar/#{self.id}?" + File.mtime(avatar_path).to_i.to_s
      end
    elsif email
      if secure
	"https://secure.gravatar.com/avatar.php?gravatar_id=#{Digest::MD5.hexdigest(self.email.downcase)}&rating=PG&size=#{size}"
      else
	"http://www.gravatar.com/avatar.php?gravatar_id=#{Digest::MD5.hexdigest(self.email.downcase)}&rating=PG&size=#{size}"
      end
    end
  end

  def display_name
    self.name
  end

#  def login(subdomain = nil)
#	  company = Company.find(:first, :conditions => ["subdomain = ?", subdomain.downcase])
#	  companyId = company.nil ? 1 : company.id
#	  User.find( :first, :conditions => [ 'username = ? AND password = ? AND company_id = ?', self.username, self.password, companyId ] )
#  end
  
  def login(company = nil)
    return if !company or !company.respond_to?(:users)
    return company.users.find(:first, :conditions => { :username => self.username, :password => self.password })
  end

  def can?(project, perm)
    @perm_cache ||= {}
    unless @perm_cache[project.id]
      @perm_cache[project.id] ||= {}
      self.project_permissions.each do | p |
        @perm_cache[p.project_id] ||= {}
        ['comment', 'work', 'close', 'report', 'create', 'edit', 'reassign', 'prioritize', 'milestone', 'grant', 'all'].each do |p_perm|
          @perm_cache[p.project_id][p_perm] = p.can?(p_perm)
        end
      end 
    end 

    (@perm_cache[project.id][perm] || false)
  end

  def can_all?(projects, perm)
    projects.each do |p|
      return false unless self.can?(p, perm)
    end
    true
  end

  def can_any?(project, perm)
    projects.each do |p|
      return true if self.can?(p, perm)
    end
    false
  end
  
  def admin?
    self.admin > 0
  end

  ###
  # Returns true if this user is allowed to view the clients section
  # of the website.
  ###
  def can_view_clients?
    self.admin? or 
      (self.read_clients? and self.option_externalclients?)
  end

  # Returns true if this user is allowed to view the given task.
  def can_view_task?(task)
    projects.include?(task.project) || task.linked_users.include?(self)
  end

  # Returns a fragment of sql to restrict tasks to only the ones this 
  # user can see
  def user_tasks_sql
    res = []
    if self.projects.any?
      res << "tasks.project_id in (#{ all_project_ids.join(",") })"
    end

    res << "task_owners.user_id = #{ self.id }"
    res << "notifications.user_id = #{ self.id }"
    
    res = res.join(" or ")
    return "(#{ res })"
  end
  
  # Returns an array of all project ids that this user has
  # access to. Even completed projects will be included.
  def all_project_ids
    @all_project_ids ||= all_projects.map { |p| p.id }
  end

  # Returns an array of all customers this user has access to 
  # (through projects). 
  # If options is passed, those options will be passed to the find.
  def customers(options = {})
    company.customers.all(search_options_through_projects("customers", options))
  end

 # Returns an array of all milestone this user has access to 
  # (through projects). 
  # If options is passed, those options will be passed to the find.
  def milestones(options = {})
    company.milestones.all(search_options_through_projects("milestones", options))
  end

  def currently_online
    User.find(:all, :conditions => ["company_id = ? AND last_seen_at > ?", self.company, Time.now.utc-5.minutes])
  end

  def moderator_of?(forum)
    moderatorships.count(:all, :conditions => ['forum_id = ?', (forum.is_a?(Forum) ? forum.id : forum)]) == 1
  end

  def online?
    (!self.last_ping_at.nil? && self.last_ping_at > 3.minutes.ago.utc)
  end

  def offline?
    !self.online?
  end
  
  def idle?
    ( (!self.last_ping_at.nil?) && (self.last_ping_at > 3.minutes.ago.utc) && (self.last_seen_at.nil? || self.last_seen_at < 10.minutes.ago.utc))
  end
  
  def online_status_name
    if self.last_ping_at.nil? || self.last_ping_at < 3.minutes.ago.utc
      return "<span class=\"status-offline\">#{self.name} (offline)</span>"
    elsif self.last_seen_at.nil? || self.last_seen_at < 10.minutes.ago.utc
      return "<span class=\"status-idle\">#{self.name} (idle)</span>"
    end
    "<span class=\"status-online\">#{self.name}</span>"
  end

  def tz
    unless @tz
      @tz = Timezone.get(self.time_zone)
    end
    @tz
  end

  # Get date formatter in a form suitable for jQuery-UI
  def dateFormat
  	return 'mm/dd/yy' if self.date_format == '%m/%d/%Y'
  	return 'dd/mm/yy' if self.date_format == '%d/%m/%Y' 
  	return 'yy-mm-dd' if self.date_format == '%Y-%m-%d'
  end
  
  def shout_nick
    n = nil
    # Upcase first character of all words in a string, and truncate all middle words with first character + ".".
	# eg. "elvis aaron presley" => "Elvis A. Presley"
    # n = name.gsub(/[^\s\w]+/, '').split(" ") if name
    # n = ["Anonymous"] if(n.nil? || n.empty?)

    # "#{n[0].chars.capitalize} #{n[1..-1].collect{|e| e.chars[0..0].upcase + "."}.join(' ')}".strip
    
    # disabled since it seems superfluous and doesn't work in Rails 2.3
    n= name
  end

  def online_status_icon
    if self.idle?
      "/images/presence-idle.png"
    elsif self.online?
      "/images/presence-online.png"
    else 
      "/images/presence-offline.png"
    end
  end

  def to_s
    str = [ name ]
    str << "(#{ customer.name })" if customer

    str.join(" ")
  end

  # Returns an array of all task filters this user can see
  def visible_task_filters
    if @visible_task_filters.nil?
      @visible_task_filters = (task_filters.visible + company.task_filters.shared.visible).uniq
      @visible_task_filters = @visible_task_filters.sort_by { |tf| tf.name.downcase.strip }
    end

    return @visible_task_filters
  end

  private

  # Sets up search options to use in a find for things linked to 
  # through projects.
  # See methods customers and milestones.
  def search_options_through_projects(lookup, options = {})
    conditions = []
    conditions << User.send(:sanitize_sql_for_conditions, options[:conditions])
    conditions << User.send(:sanitize_sql_for_conditions, [ "projects.id in (?)", all_project_ids ])
    conditions = conditions.compact.map { |c| "(#{ c })" }
    options[:conditions] = conditions.join(" and ")

    options[:include] ||= []
    options[:include] << (lookup == "milestones" ? :project : :projects)

    options = options.merge(:order => "lower(#{ lookup }.name)")    

    return options
  end

  # Sets the date time format for this user to a sensible default
  # if it hasn't already been set
  def set_date_time_formats
    first_user = company.users.detect { |u| u != self }

    if first_user and first_user.time_format and first_user.date_format
      self.time_format = first_user.time_format
      self.date_format = first_user.date_format
    else
      self.date_format = "%d/%m/%Y"
      self.time_format = "%H:%M"
    end
  end

end

# == Schema Information
#
# Table name: users
#
#  id                         :integer(4)      not null, primary key
#  name                       :string(200)     default(""), not null
#  username                   :string(200)     default(""), not null
#  password                   :string(200)     default(""), not null
#  company_id                 :integer(4)      default(0), not null
#  created_at                 :datetime
#  updated_at                 :datetime
#  email                      :string(200)
#  last_login_at              :datetime
#  admin                      :integer(4)      default(0)
#  time_zone                  :string(255)
#  option_tracktime           :integer(4)
#  option_externalclients     :integer(4)
#  option_tooltips            :integer(4)
#  seen_news_id               :integer(4)      default(0)
#  last_project_id            :integer(4)
#  last_seen_at               :datetime
#  last_ping_at               :datetime
#  last_milestone_id          :integer(4)
#  last_filter                :integer(4)
#  date_format                :string(255)     not null
#  time_format                :string(255)     not null
#  send_notifications         :integer(4)      default(1)
#  receive_notifications      :integer(4)      default(1)
#  uuid                       :string(255)     not null
#  seen_welcome               :integer(4)      default(0)
#  locale                     :string(255)     default("en_US")
#  duration_format            :integer(4)      default(0)
#  workday_duration           :integer(4)      default(480)
#  posts_count                :integer(4)      default(0)
#  newsletter                 :integer(4)      default(1)
#  option_avatars             :integer(4)      default(1)
#  autologin                  :string(255)     not null
#  remember_until             :datetime
#  option_floating_chat       :boolean(1)      default(TRUE)
#  days_per_week              :integer(4)      default(5)
#  enable_sounds              :boolean(1)      default(TRUE)
#  create_projects            :boolean(1)      default(TRUE)
#  show_type_icons            :boolean(1)      default(TRUE)
#  receive_own_notifications  :boolean(1)      default(TRUE)
#  use_resources              :boolean(1)
#  customer_id                :integer(4)
#  active                     :boolean(1)      default(TRUE)
#  read_clients               :boolean(1)      default(FALSE)
#  create_clients             :boolean(1)      default(FALSE)
#  edit_clients               :boolean(1)      default(FALSE)
#  can_approve_work_logs      :boolean(1)
#  auto_add_to_customer_tasks :boolean(1)
#

