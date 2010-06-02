class Task
  module Assignments
    augmentation do 

      def mark_new_assignment(assignment)
        @new_assignments ||= []
        @new_assignments << assignment unless @new_assignments.include? assignment
      end

      def mark_removed_assignment(assignment)
        @removed_assignments ||= []
        @removed_assignments << assignment unless @removed_assignments.include? assignment
      end

      def reject_if_already_assigned(user)
        throw "User already assigned" if self.assigned_users.exists?(user.id)
      end

      def reject_if_already_notified(user)
        throw "User already notified" if self.notified_users.exists?(user.id)
      end

      def update_assignment_properties(users, update, create, remove=nil)
        users = [users].flatten
        update_assignment_properties_with_ids(users.map { |u| u.id }, update, create, remove)
      end

      def update_assignment_properties_with_ids(user_ids, update, create, remove=nil)
        user_ids = [user_ids].flatten
        self.assignments.each do |a|
          if user_ids.include? a.user_id
            a.update_attributes(update)
          elsif remove
            a.update_attributes(remove)
          end
          user_ids.delete a.user_id
        end

        user_ids.each do |u_id|
          self.assignments.create(create.merge({:user_id => u_id}))
        end
        self.assignments(true)
        if update[:assigned] and !self.new_record?
          self.recipient_users(true)
          send_notifications
        end
      end

      module UserAssignments

        def set(users)
          [users].flatten.each { |u| proxy_owner.mark_new_assignment(u) }
          proxy_owner.update_assignment_properties(users,
            {:assigned => true, :notified => false},
            {:assigned => true, :notified => false},
            {:assigned => false}
          )
          proxy_owner.assigned_users(true)
        end

        def add(users)
          [users].flatten.each { |u| proxy_owner.mark_new_assignment(u) }
          proxy_owner.update_assignment_properties(users,
            {:assigned => true},
            {:assigned => true, :notified => false}
          )
          proxy_owner.assigned_users(true)
        end

      end

      module NotifiedAssignments

        def set(users)
          proxy_owner.update_assignment_properties(users,
            {:notified => true, :assigned => false},
            {:notified => true, :assigned => false},
            {:notified => false}
          )
          proxy_owner.notified_users(true)
        end

        def add(users)
          proxy_owner.update_assignment_properties(users,
            {:notified => true},
            {:notified => true, :assigned => false}
          )
          proxy_owner.notified_users(true)
        end

      end

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
      # Returns true if user should be set to be notified about this task
      # by default.
      ###
      def should_be_notified?(user)
        return self.new_record? ? user.receive_notifications? : self.notified_users.exists?(user.id)
      end

      def bookmark(user, bookmarked=nil)
        a = self.assignments.find(:first, :conditions => {:user_id => user.id})
        if a
          bookmarked ||= !a.bookmarked?
          a.update_attribute(:bookmarked, bookmarked)
        end
      end

      def bookmarked?(user)
        self.assignments.exists?(["assignments.user_id = ? and assignments.bookmarked = true", user.id])
      end

      has_many  :assignments, :after_add => :mark_new_assignment, :after_remove => :mark_removed_assignment

      has_many  :assigned_users, :through => :assignments, :class_name => 'User', :source => :user, :conditions => "assignments.assigned = true",
        :extend => UserAssignments, :before_add => :reject_if_already_assigned

      has_many  :notified_users, :through => :assignments, :source => :user, :conditions => "assignments.notified = true",
        :extend => NotifiedAssignments, :before_add => :reject_if_already_notified

      has_many  :recipient_users, :through => :assignments, :source => :user, :conditions => "assignments.notified = true and users.receive_notifications = true"

      has_many  :watchers, :through => :assignments, :source => :user, :conditions => "assignments.notified = false and assignments.assigned = false"

      has_many  :bookmarked_users, :through => :assignments, :source => :user, :conditions => 'assignments.bookmarked = true'

    end
  end
end
