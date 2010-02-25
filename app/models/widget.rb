# A widget on the Activities page.


class Widget < ActiveRecord::Base
  belongs_to :company
  belongs_to :user
  belongs_to :filter, :class_name => "TaskFilter"

  validates_presence_of :name

  def name
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

  def order_by_sql
    conditions, order = nil
    case self.order_by
      when 'priority':
        order = "task_owners.user_id = #{self.user_id} and task_owners.unread = true desc, tasks.due_at asc, tasks.priority asc, tasks.completed_at asc, tasks.task_num asc"
      when 'due_date_desc':
        order = 'UNIX_TIMESTAMP(UTC_TIMESTAMP()) - UNIX_TIMESTAMP(tasks.due_at) desc'
      when 'due_date_asc':
        order = 'UNIX_TIMESTAMP(UTC_TIMESTAMP()) - UNIX_TIMESTAMP(tasks.due_at) asc'
      when 'duration_desc':
        order = 'tasks.worked_minutes / tasks.duration desc'
      when 'duration_asc':
        order = 'tasks.worked_minutes / tasks.duration asc'
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
    end
    return order, conditions
  end

end
