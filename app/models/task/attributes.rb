class Task
  # Module regrouping functions representing custom attributes or statuses for a task.
  module Attributes
    augmentation do

      def status_type
        Task.status_types[self.status]
      end

      def Task.status_type(type)
        Task.status_types[type]
      end

      def Task.status_types
        ["Open", "Closed", "Won't fix", "Invalid", "Duplicate"]
      end

      def open?
        self.status == 0
      end

      def closed?
        self.status > 0
      end

      def done?
        self.status > 1 && self.completed_at != nil
      end

      def ready?
        self.dependencies.reject{ |t| t.done? }.empty?
      end

      def active?
        self.hide_until.nil? || self.hide_until < Time.now.utc
      end

      def worked_on?
        self.sheets.size > 0
      end

      def set_task_num(company_id = nil)
        company_id ||= company.id

        num = Task.maximum('task_num', :conditions => ["company_id = ?", company_id]) 
        num ||= 0
        num += 1 

        @attributes['task_num'] = num
      end

      def time_left
        res = 0
        if self.due_at != nil
          res = self.due_at - Time.now.utc
        end
        res
      end

      def overdue?
        self.due_date ? (self.due_date.to_time <= Time.now.utc) : false
      end

      def scheduled_overdue?
        self.scheduled_date ? (self.scheduled_date.to_time <= Time.now.utc) : false
      end

      def started?
        worked_seconds > 0 || self.worked_on?
      end

      def due_date
        if self.due_at?
          self.due_at
        elsif self.milestone_id.to_i > 0 && milestone && milestone.due_at?
          milestone.due_at
        else 
          nil
        end 
      end

      def scheduled_date
        if self.scheduled?
          if self.scheduled_at?
            self.scheduled_at
          elsif self.milestone
            self.milestone.scheduled_date
          end 
        else 
          if self.due_at?
            self.due_at
          elsif self.milestone
            self.milestone.scheduled_date
          end
        end 
      end 

      def scheduled_due_at
        if self.scheduled?
          self.scheduled_at
        else 
          self.due_at
        end 
      end 

      def scheduled_duration
        if self.scheduled?
          @attributes['scheduled_duration'].to_i
        else 
          self.duration.to_i
        end 
      end

      def seconds_left
        self.duration - self.worked_seconds
      end

      def scheduled_seconds_left
        d = self.scheduled_duration - self.worked_seconds
        d = 240 if d < 0 && self.scheduled_duration > 0
        d = 0 if d < 0
        d
      end 

      def overworked?
        ((self.duration - self.worked_seconds) < 0 && (self.duration) > 0)
      end

      def due
        due = self.due_at
        due = self.milestone.due_at if(due.nil? && self.milestone_id.to_i > 0 && self.milestone)
        due
      end
      
    end
  end
end
