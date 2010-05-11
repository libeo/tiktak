class Task
  module ViewHelpers
    augmentation do

      def full_name
        if self.project
          self.project.full_name
        else 
          ""
        end 
      end

      def full_name_without_links
        self.project.full_name
      end

      def issue_name
        "[##{self.task_num}] #{self[:name]}"
      end

      def issue_num
        if self.status > 0
          "<strike>##{self.task_num}</strike>"
        else
          "##{self.task_num}"
        end
      end

      def status_name
        "#{self.issue_num} #{self.name}"
      end
      
      def owners
        o = self.assigned_users.collect{ |u| u.name}.join(', ')
        o = "Unassigned" if o.nil? || o == ""
        o
      end

      def to_tip(options = { })
        unless @tip
          owners = "No one"
          owners = self.users.collect{|u| u.name}.join(', ') unless self.users.empty?

          res = "<table id=\"task_tooltip\" cellpadding=0 cellspacing=0>"
          res << "<tr><th>#{_('Summary')}</td><td>#{self.name}</tr>"
          res << "<tr><th>#{_('Project')}</td><td>#{self.project.full_name}</td></tr>"
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

      def description_wrapped
        unless description.blank?
          truncate( word_wrap(self.description, :line_width => 80), :length => 1000)
        else
          nil
        end
      end 

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

      def todo_status
        todos.empty? ? "[#{_'To-do'}]" : "[#{sprintf("%.2f%%", todos.select{|t| t.completed_at }.size / todos.size.to_f * 100.0)}]"
      end

      def todo_count
        "#{sprintf("%d/%d", todos.select{|t| t.completed_at }.size, todos.size)}"
      end

      def order_date
        [self.started_at.to_i]
      end 

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
