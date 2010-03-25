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
    options = {:duration_format => self.duration_format}
    options[:subject] = self.template_transform(self.message_subject, [task, user]) if self.message_subject != ""
    options[:header] = self.template_transform(self.message_header, [task, user]) if self.message_header and self.message_header != ""

    if state == :created
      Notifications::deliver_created(task, user, emails, "", options) 
    else
      Notifications::deliver_changed(state, task, user, emails, "", options)
    end
	end

	def send_project_notice(project, user)
		emails = merge_general_emails(self.get_emails)
    options = {:subject => self.template_transform(self.message_subject, [project, user]),
      :header => self.template_transform(self.message_header, [project, user]),
      :duration_format => self.duration_format
    }
		Notifications::deliver_created_project(project, user, emails, "", options)
	end

	def self.get_general_groups(options={})
      options.delete(:conditions)
      options = {:select => 'notice_groups.message_header, notice_groups.message_subject, notice_groups.duration_format, users.email, users.id, users.name', :include => :users, :conditions => "notice_groups.id not in (select notice_group_id from notice_groups_projects)"}
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

  def template_transform(template, elements)
    result = template.dup
    regex = Regexp.new(":::(((#{elements.map{|e|e.class.to_s.downcase}.join('|')})\\.)?(.+?)):::", Regexp::MULTILINE, 'u')
    template.scan(regex) do |m|
      if m[2]
        element = elements.select{ |e| e.class.to_s.downcase == m[2] }.first
        result.sub!(":::#{m[0]}:::", element.attributes[m[3]])
      else
        result.sub!(":::#{m[0]}:::", "")
      end
    end
    return result
  end

end
