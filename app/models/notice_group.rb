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

	def send_task_notice(task, user)
		emails = merge_general_emails(self.get_emails)
		Notifications::deliver_created(task, user, emails, "", Time.now, self.duration_format)
	end

	def send_project_notice(project, user)
		emails = merge_general_emails(self.get_emails)
		Notifications::deliver_created_project(project, user, emails)
	end

	def self.get_general_groups
      return NoticeGroup.find_by_sql("select * from notice_groups where id not in (select notice_group_id from notice_groups_projects)")
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
