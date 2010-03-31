class Task
  # Module regrouping functions representing custom attributes or statuses for a task.
  module Attributes
    augmentation do

      # Boolean, true if the task is closed
      def done?
        self.status > 1 && self.completed_at != nil
      end

      # Boolean, true if the task is closed
      def done
        self.status > 1
      end

      # Boolean, true if all dependant tasks are done
      def ready?
        self.dependencies.reject{ |t| t.done? }.empty?
      end

      # Boolean, true if the task is visible (not hidden)
      def active?
        self.hide_until.nil? || self.hide_until < Time.now.utc
      end

      # Boolean, true if the task is being worked on right now 
      def worked_on?
        self.sheets.size > 0
      end

      # Create a task number for the task
      # company_id : company id
      def set_task_num(company_id = nil)
        company_id ||= company.id

        num = Task.maximum('task_num', :conditions => ["company_id = ?", company_id]) 
        num ||= 0
        num += 1 

        @attributes['task_num'] = num
      end

      # Number of seconds left on the task before all the time is used
      def time_left
        res = 0
        if self.due_at != nil
          res = self.due_at - Time.now.utc
        end
        res
      end

      # Boolean, true if the total time worked on the task has exceeded the estimated time
      def overdue?
        self.due_date ? (self.due_date.to_time <= Time.now.utc) : false
      end

      # Boolean true if the total time workes on the task has axceeded the estimated scheduled time
      # TODO: WTF does 'scheduled' do ? repeat tasks maybe ?
      def scheduled_overdue?
        self.scheduled_date ? (self.scheduled_date.to_time <= Time.now.utc) : false
      end

      # Boolean, true if someone has added time on the task
      def started?
        worked_minutes > 0 || self.worked_on?
      end

      # Returns the due date (if any), otherwise the milestone date (if any), otherwise nil
      def due_date
        if self.due_at?
          self.due_at
        elsif self.milestone_id.to_i > 0 && milestone && milestone.due_at?
          milestone.due_at
        else 
          nil
        end 
      end

      # Returns the scheduled due date (if any), otherwise the milestone date (if any), otherwise nil
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

      # Returns the scheduled due date (if any), otherwise the due date
      def scheduled_due_at
        if self.scheduled?
          self.scheduled_at
        else 
          self.due_at
        end 
      end 

      # Returns the scheduled duration in seconds (if any) otherwise the task duration
      def scheduled_duration
        if self.scheduled?
          @attributes['scheduled_duration'].to_i
        else 
          self.duration.to_i
        end 
      end

      # Returns the time left on the task in minutes
      def minutes_left
        self.duration.to_i - self.worked_minutes 
      end

      # Returns the scheduled time left on the task in minutes
      def scheduled_minutes_left
        d = self.scheduled_duration.to_i - self.worked_minutes 
        d = 240 if d < 0 && self.scheduled_duration.to_i > 0
        d = 0 if d < 0
        d
      end 

      # Boolean, true if the time worked on the task exceeds the estimated duration
      def overworked?
        ((self.duration.to_i - self.worked_minutes) < 0 && (self.duration.to_i) > 0)
      end

      # Returns the date the task is due (if any) otherwise the milestone date
      def due
        due = self.due_at
        due = self.milestone.due_at if(due.nil? && self.milestone_id.to_i > 0 && self.milestone)
        due
      end
      
    end
  end
end
