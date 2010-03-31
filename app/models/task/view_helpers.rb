class Task
  module ViewHelpers
    augmentation do

      # Returns a html code with links representing various information about the tasks' associations
      # using slashes to seperate the information
      # Information shown :
      # Client / Project / Tags (if any)
      def full_name
        if self.project
          [self.project.full_name, self.full_tags].join(' / ')
        else 
          ""
        end 
      end

      # Returns html code containing links to all the tags associated to the task.
      # The links are seperated by a slash
      def full_tags
        self.tags.collect{ |t| "<a href=\"/tasks/list/?tag=#{t.name}\" class=\"description\">#{t.name.capitalize.gsub(/\"/,'&quot;')}</a>" }.join(" / ")
      end

      # Returns html code wihout links representing various information about the tasks' associations
      # using slashes to seperate the information
      # Information shown :
      # Client / Project / Tags (if any)
      def full_name_without_links
        [self.project.full_name, self.full_tags_without_links].join(' / ')
      end

      # Returns html code without links representing all the tags associated to the task.
      # The tags are seperated by a slash
      def full_tags_without_links
        self.tags.collect{ |t| t.name.capitalize }.join(" / ")
      end

      # Retruns a textual representation of the task containing the task number and the task name.
      # Format : [task number] [task name]
      def issue_name
        "[##{self.task_num}] #{self[:name]}"
      end

      # Returns html code representing the task containing the task number.
      # THe task number is striked if the task is closed.
      def issue_num
        if self.status > 1
          "<strike>##{self.task_num}</strike>"
        else
          "##{self.task_num}"
        end
      end

      # Returns a textual representation of the tasks' number and the tasks' name..
      # The task number is striked if the task is closed.
      def status_name
        "#{self.issue_num} #{self.name}"
      end
      
      # Returns a comma-seperated list of all the people who are assigned to the task.
      # Shows 'Unassigned' if tghere are no people assigned.
      def owners
        o = self.users.collect{ |u| u.name}.join(', ')
        o = "Unassigned" if o.nil? || o == ""
        o
      end

      # Returns the html code to insert in a links' tip property
      # Information shown in the tip :
      # Task description, project, tags, people assigned, requested by, 
      # task status, milestone, status, due date, dependencies, dependants, time worked.
      # options : optional hash {
      # :user => current_user,
      # :duration_format => duration format,
      # :workday_duration => number of minutes in a work day
      # :days_per_week => number of days in a work week }
      def to_tip(options = { })
        unless @tip
          owners = "No one"
          owners = self.users.collect{|u| u.name}.join(', ') unless self.users.empty?

          res = "<table id=\"task_tooltip\" cellpadding=0 cellspacing=0>"
          res << "<tr><th>#{_('Summary')}</td><td>#{self.name}</tr>"
          res << "<tr><th>#{_('Project')}</td><td>#{self.project.full_name}</td></tr>"
          res << "<tr><th>#{_('Tags')}</td><td>#{self.full_tags}</td></tr>" unless self.full_tags.blank?
          res << "<tr><th>#{_('Assigned To')}</td><td>#{owners}</td></tr>"
          res << "<tr><th>#{_('Requested By')}</td><td>#{self.requested_by}</td></tr>" unless self.requested_by.blank?
          res << "<tr><th>#{_('Status')}</td><td>#{_(self.status_type)}</td></tr>"
          res << "<tr><th>#{_('Milestone')}</td><td>#{self.milestone.name}</td></tr>" if self.milestone_id.to_i > 0
          res << "<tr><th>#{_('Completed')}</td><td>#{options[:user].tz.utc_to_local(self.completed_at).strftime_localized(options[:user].date_format)}</td></tr>" if self.completed_at
          res << "<tr><th>#{_('Due Date')}</td><td>#{options[:user].tz.utc_to_local(due).strftime_localized(options[:user].date_format)}</td></tr>" if self.due
          unless self.dependencies.empty?
            res << "<tr><th valign=\"top\">#{_('Dependencies')}</td><td>#{self.dependencies.collect { |t| t.issue_name }.join('<br />')}</td></tr>"
          end
          unless self.dependants.empty?
            res << "<tr><th valign=\"top\">#{_('Depended on by')}</td><td>#{self.dependants.collect { |t| t.issue_name }.join('<br />')}</td></tr>"
          end
          res << "<tr><th>#{_('Progress')}</td><td>#{format_duration(self.worked_minutes, options[:duration_format], options[:workday_duration], options[:days_per_week])} / #{format_duration( self.duration.to_i, options[:duration_format], options[:workday_duration], options[:days_per_week] )}</tr>"
          res << "<tr><th>#{_('Description')}</th><td class=\"tip_description\">#{self.description_wrapped.gsub(/\n/, '<br/>').gsub(/\"/,'&quot;').gsub(/</,'&lt;').gsub(/>/,'&gt;')}</td></tr>" unless self.description.blank?
          res << "</table>"
          @tip = res.gsub(/\"/,'&quot;')
        end 
        @tip
      end

      # Returns a textual representation of the description wrapped to 80 characters per line 
      # and no longer than 1000 characters
      def description_wrapped
        unless description.blank?
          truncate( word_wrap(self.description, :line_width => 80), :length => 1000)
        else
          nil
        end
      end 

      # Returns the css classes to apply on the task row. 
      # The css classes help in visually identifying a tasks' status
      def css_classes
        unless @css
          @css = case self.status
                 when 0 then ""
                 when 1 then " in_progress"
                 when 2 then " closed"
                 else 
                   " invalid"
                 end
        end   
        @css
      end

      # Returns a textual representation indicating what is left in the todo list
      def todo_status
        todos.empty? ? "[#{_'To-do'}]" : "[#{sprintf("%.2f%%", todos.select{|t| t.completed_at }.size / todos.size.to_f * 100.0)}]"
      end

      # Returns a textual represntation indicating how many todos are left on a total number of todos.
      # Format : num of todos left/num total todos
      def todo_count
        "#{sprintf("%d/%d", todos.select{|t| t.completed_at }.size, todos.size)}"
      end

      # Returns an array with a timestamp of when the task started
      def order_date
        [self.started_at.to_i]
      end 

      # Returns a css class indicating if the worked time has been exceeded
      def worked_and_duration_class
        if worked_minutes > duration
          "overtime"
        else 
          ""
        end 
      end 
      
    end
  end
end
