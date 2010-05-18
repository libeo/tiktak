# A widget on the Activities page.


class Widget < ActiveRecord::Base
  belongs_to :company
  belongs_to :user
  belongs_to :filter, :class_name => "TaskFilter"

  RSS_CAPABLE_TYPES = [0, 2, 11]
  ICAL_CAPABLE_TYPES = [2]

  validates_presence_of :name

  def rss_capable?
    RSS_CAPABLE_TYPES.include? self.widget_type
  end

  def ical_capable?
    ICAL_CAPABLE_TYPES.include? self.widget_type
  end

  def name_and_type
    res = ""
    if self.filter_by && self.filter_by.length > 0
      begin
        res << case self.filter_by[0..0]
               when 'c'
                 User.find(self.user_id).company.customers.find(self.filter_by[1..-1]).name
               when 'p'
                 User.find(self.user_id).projects.find(self.filter_by[1..-1]).name
               when 'm'
                 m = Milestone.find(self.filter_by[1..-1], :conditions => ["project_id IN (#{User.find(self.user_id).projects.collect(&:id).join(',')})"])
                 "#{m.project.name} / #{m.name}"
               when 'u'
                 _('[Unassigned]')
               else 
                 ""
               end 
      rescue
        res << _("Invalid Filter")
      end 
    end 
    res << " [#{_'Mine'}]" if self.mine?
    "#{@attributes['name']}#{ res.empty? ? "" : " - #{res}"}"
  end


  def type_text
    res = ""
    if self.filter_by && self.filter_by.length > 0
      begin
        res << case self.filter_by[0..0]
               when 'c'
                 User.find(self.user_id).company.customers.find(self.filter_by[1..-1]).name
               when 'p'
                 User.find(self.user_id).projects.find(self.filter_by[1..-1]).name
               when 'm'
                 m = Milestone.find(self.filter_by[1..-1], :conditions => ["project_id IN (#{User.find(self.user_id).projects.collect(&:id).join(',')})"])
                 "#{m.project.name} / #{m.name}"
               when 'u'
                 _('[Unassigned]')
               else 
                 ""
               end 
      rescue
        res << _("Invalid Filter")
      end 
    end 
      res << " [#{_'Mine'}]" if self.mine?
      return res
  end

  def order_by_sql
    order = nil
    conditions = []
    includes = []
    case self.order_by
      when 'priority':
        order = "assignments.user_id = #{self.user_id} and assignments.bookmarked = true desc, UNIX_TIMESTAMP(UTC_TIMESTAMP()) - UNIX_TIMESTAMP(tasks.due_at) desc, tasks.completed_at asc, tasks.task_num asc"
      when 'due_date_desc':
        order = 'UNIX_TIMESTAMP(UTC_TIMESTAMP()) - UNIX_TIMESTAMP(tasks.due_at) desc'
      when 'due_date_asc':
        order = 'UNIX_TIMESTAMP(UTC_TIMESTAMP()) - UNIX_TIMESTAMP(tasks.due_at) asc'
      when 'duration_desc':
        order = 'tasks.worked_seconds / tasks.duration desc'
      when 'duration_asc':
        order = 'tasks.worked_seconds / tasks.duration asc'
      when 'date_desc':
        order = 'tasks.created_at desc'
      when 'date_asc':
        order = 'tasks.created_at asc'
      when 'mod_desc':
        order = 'tasks.updated_at desc'
      when 'mod_asc':
        order = 'tasks.updated_at asc'
      when 'created':
        conditions << "tasks.creator_id = #{self.user_id}"
        order = 'tasks.created_at desc'
      when 'last_clocked_desc'
        conditions << 'work_logs.duration > 0'
        order = 'work_logs.started_at desc'
        includes << :work_logs
    end
    return order, conditions.join(" AND "), includes
  end

end
