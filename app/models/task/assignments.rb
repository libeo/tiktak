class Task
  module Assignments
    augmentation do

      def mark_new_assignment(assignment)
        @new_assignments ||= []
        @new_assignments << assignment
      end

      def mark_removed_assignment(assignment)
        @removed_assignments ||= []
        @removed_assignments << assignment
      end

      def changed_assigned_users? 
        self.assignments.select { |a| a.assigned? and (a.changed? or a.new_record?) }.length > 0 or !@new_assignments.nil? or !@removed_assignments.nil?
      end

      private

      def reject_if_already_assigned(user)
        throw "User already assigned" if self.assigned_users.exists?(user.id)
      end

      def reject_if_already_notified(user)
        throw "User already notified" if self.notified_users.exists?(user.id)
      end

      def reject_if_already_notified(user)
        throw "User already notified" if self.notified_users.exists?(user.id)
      end

      def reject_if_already_notified_last_change(user)
        throw "User already notified of last change" if self.notified_last_change.exists?(user.id)
      end

      def reject_if_already_unread(user)
        throw "User already unread" if self.unread_users.exists?(user.id)
      end

      def update_assignment_properties(users, property, create_attributes, absolute = true)
        users = [users].flatten
        update_assignment_properties_with_ids(users.map{|u|u.id}, property, create_attributes, absolute)
      end

      def update_assignment_properties_with_ids(user_ids, property, create_attributes, absolute = true)
        self.assignments.all(:select => 'id, user_id, assigned, notified, notified_last_change').each do |a|
          if user_ids.include?(a.user_id)
            a.update_attributes(create_attributes)
            self.mark_new_assignment(a)
          elsif absolute == true
            a.update_attribute(property, false)
          end
          user_ids.delete(a.user_id)
        end

        user_ids.each do |u| 
          self.mark_new_assignment(self.assignments.create(create_attributes.merge({:user_id => u})))
          #self.assignments.create(create_attributes.merge({:user_id => u}))
        end
        #send notifications that assignments have changed
        self.send_notifcations
        #refresh assignments to include also those that have been created
        self.assignments(true)
      end

      #def update_assignment_properties_with_ids(user_ids, property, create_attributes, absolute = true)
      #  Assignment.update_all("assignments.#{property.to_s} = true", ["assignments.task_id = ? and assignments.user_id in (?)", self.id, user_ids])
      #  Assignment.update_all("assignments.#{property.to_s} = false", ["assignments.task_id = ? and assignments.user_id not in (?)", self.id, user_ids]) if absolute
      #  new = user_ids - self.assignments.all(:select => 'user_id').map { |a| a.user_id }
      #  new.each { |u| self.assignments.create(create_attributes.merge({:user_id => u})) }
      #  self.assignments(true)
      #end

      public

      ###
      # Returns an array of email addresses of people who should be 
      # notified about changes to this task.
      # user_who_made_change : User who modified the task (if any)
      ###
      def notification_email_addresses(user = nil)
        recipients = self.notified_users.all(:select => 'users.email', :conditions => 'users.receive_notifications = true').map { |u| u.email }
        recipients.delete user if user and !user.receive_notifications?
        recipients += self.notify_emails.split(',') if self.notify_emails
        recipients
      end
      alias :all_notify_emails :notification_email_addresses

      ###
      # All users will be assigned to the task and will be notified of any changes to the task
      ###
      def notified_users=(users)
        update_assignment_properties(users, :notified, {:notified => true, :assigned => false})
        self.notified_users(true)
      end

      def notification_ids=(user_ids)
        update_assignment_properties_with_ids(user_ids, :notified, {:notified => true, :assigned => false})
        self.notified_users(true)
      end

      def add_notified_users(users)
        update_assignment_properties(users, :notified, {:notified => true}, false)
        self.notified_users(true)
      end

      ###
      # All users will be assigned to the task and will be able to add work time to the task
      ###
      def assigned_users=(users)
        update_assignment_properties(users, :assigned, {:notified => false, :assigned => true})
        self.assigned_users(true)
      end

      def assigned_user_ids=(user_ids)
        update_assignment_properties_with_ids(user_ids, :assigned, {:notified => false, :assigned => true})
        self.assigned_users(true)
      end

      def add_assigned_users(users)
        update_assignment_properties(users, :assigned, {:assigned => true, :notified => false})
        self.assigned_users(true)
      end

      ###
      # The notified_last_change flag is used to keep track of users who have been sucessfully notified of the last modifications on the task.
      # All users will be set as have been notified
      ###
      def notified_last_change=(users)
        Assignment.update_all('notified = true, notified_last_change = true', ['task_id = ? and user_id in (?)', self.id, users.map { |u| u.id }])
        Assignment.update_all('notified_last_change = false', ['task_id = ? and notified = false and user_id not in (?)', self.id, users.map { |u| u.id }])
        new = self.assignments.all(:select => 'user_id').map { |a| a.user_id } - users.map { |u| u.id }
        new.each { |n| self.assignments.create({:assigned => false, :notified => true, :notified_last_change => true, :user_id => n}) }
        self.assignments(true)
        self.notified_last_change
      end

      def add_notified_last_change(users)
        update_assignment_properties(users, :notified_last_change, {:assigned => false, :notified => true, :notified_last_change => true}, false)
        self.notified_last_change(users)
      end

      def add_notified_last_change_ids(user_ids)
        update_assignment_properties_with_ids(user_ids, :notified_last_change, {:assigned => false, :notified => true, :notified_last_change => true}, false)
        self.notified_last_change(users)
      end

      ###
      # Unread users are users who have not read the notification sent. 
      # A star will appear next to the task in task listings for unread notifications
      # This function sets the unread flag for the specified users
      ###
      def unread_users=(users)
        update_assignments_properties(users, :unread, {:unread => true})
        self.unread_users(users)
      end

      def unread_user_ids=(user_ids)
        update_assignments_properties_with_ids(user_ids, :unread, {:unread => true})
        self.unread_users(users)
      end

      def add_unread_users(users)
        update_assignments_properties(users, :unread, {:unread => true}, false)
        self.unread_users(users)
      end

      ###
      # Returns true if user should be set to be notified about this task
      # by default.
      ###
      def should_be_notified?(user)
        return self.new_record? ? user.receive_notifications? : self.notified_users.exists?(user.id)
      end

      ###
      # This method will mark this task as unread for any
      # setup watchers or task assigned_users.
      # The exclude param should be a user or array of users whose unread
      # status will not be updated. For example, the person who wrote a
      # comment should probably be excluded.
      ###
      def mark_as_unread(exclude = [])
        exclude = [ exclude ].flatten.map { |e| e.id } # make sure it's an array.
        if exclude.length > 0
          modify = self.assignments.all(:conditions => ['user_id not in (?)', exclude], :select => 'id, unread')
        else
          modify = self.assignments.all(:select => 'id, unread')
        end
        modify.each { |m| m.update_attribute(:unread, true) }
        self.assignments(true)
      end

      ###
      # Sets this task as read for user.
      # If read is passed, and false, sets the task
      # as unread for user.
      ###
      def set_task_read(users, read = true)
        users = [ users ].flatten.map { |u| u.id }
        self.assignments.all(:conditions => ['user_id in (?)', users]).each do |a|
          a.update_attribute(:unread, !read)
        end
        self.assignments(true)
      end

      ###
      # Returns true if this task is marked as unread for user.
      ###
      def unread?(user)
        self.assignments.exists?(['unread = true and user_id = ?', user.id])
      end

    end
  end
end
