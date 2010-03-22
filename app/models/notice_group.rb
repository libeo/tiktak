require  File.join(File.dirname(__FILE__), '../../lib/misc')

class NoticeGroup < ActiveRecord::Base
	belongs_to :companies
	has_and_belongs_to_many :users
	has_and_belongs_to_many :projects

	def merge_general_emails(emails)
        NoticeGroup.get_general_groups.each do |ng|
          emails.concat(ng.users.collect{ |u| u.email })
        end
        return emails.uniq
	end
	
	def get_emails
		return self.users.find(:all).collect{ |u| u.email }
	end

	def send_task_notice(task, user, state=:created)
		emails = merge_general_emails(self.get_emails)
    if state == :created
      Notifications::deliver_created(task, user, emails, "", Time.now, self.duration_format)
    else
      Notifications::deliver_changed(state, task, user, emails, "", Time.now)
    end
	end

	def send_project_notice(project, user)
		emails = merge_general_emails(self.get_emails)
		Notifications::deliver_created_project(project, user, emails)
	end

	def self.get_general_groups(options={})
      options.delete(:conditions)
      options = {:select => 'notice_groups.duration_format, users.email, users.id, users.name', :include => :users, :conditions => "notice_groups.id not in (select notice_group_id from notice_groups_projects)"}
      return NoticeGroup.find(:all, options)
	end

  def self.get_general_emails(options={})
    options.delete(:conditions)
    options = {:select => 'users.email', :include => :users, :conditions => 'notice_groups.id not in (select notice_group_id from notice_group_projects)'}
    return NoticeGroup.find(:all, options).map { |ng| ng.users.map { |u| u.email } }.flatten.uniq
  end

	def set_projects(project_ids)
		project_ids = [project_ids] unless project_ids.is_a?(Array)
		self.projects.clear
		Project.find(project_ids.map{ |p| p.to_i }).each do |p|
			self.projects << p
		end
	end

	def set_users(user_ids)
		project_ids = [user_ids] unless user_ids.is_a?(Array)
        self.users.clear
		User.find(user_ids.map{ |u| u.to_i }).each do |u|
			self.users << u
		end
	end

end
