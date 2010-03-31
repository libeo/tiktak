class Task
  module Assignments
    augmentation do

      ###
      # Returns an array of email addresses of people who should be 
      # notified about changes to this task.
      # user_who_made_change : User who modified the task (if any)
      ###
      def notification_email_addresses(user = nil)
        recipients = self.users.all(:select => 'users.email', :conditions => 'users.receive_notifications = true').map { |u| u.email } 
        recipients += self.notify_emails.split(',')
      end

      ###
      # Sets the task watchers for this task.
      # Existing watchers WILL be cleared by this method.
      # watcher_ids : array of user ids
      ###
      def set_watcher_ids(watcher_ids)
        return if watcher_ids.nil?

        self.notifications.destroy_all

        watcher_ids.each do |id|
          next if id.to_i == 0
          user = company.users.find(id)
          Notification.create(:user => user, :task => self)
        end
      end

      ###
      # Sets the owners of this task from owner_ids.
      # Existing owners WILL  be cleared by this method.
      # owner_ids : array of user ids
      ###
      def set_owner_ids(owner_ids)
        return if owner_ids.nil?

        self.task_owners.destroy_all

        owner_ids.each do |o|
          next if o.to_i == 0
          u = company.users.find(o.to_i)
          TaskOwner.create(:user => u, :task => self)
        end
      end

      ###
      # Sets up any task owners or watchers from the given params.
      # Any existings ones not in the given params will be removed.
      # params : hash returned by ActionController::Base#params in the task controller
      ###
      def set_users(params)
        all_users = params[:users] || []
        owners = params[:assigned] || []
        watchers = all_users - owners

        set_owner_ids(owners)
        set_watcher_ids(watchers)
      end

      ###
      # This method will mark any task_owners or notifications linked to
      # this task notified IF they are in the given array of users.
      # If not, that column will be set to false.
      ###
      def mark_as_notified_last_change(users)
        notifications = self.notifications + self.task_owners
        notifications.each do |n|
          notified = users.include?(n.user)
          n.update_attribute(:notified_last_change, notified)
        end
      end

      ###
      # Returns true if user should be set to be notified about this task
      # by default.
      ###
      def should_be_notified?(user)
        res = true
        if self.new_record?
          res = user.receive_notifications?
        else
          join = (task_owners + notifications).detect { |j| j.user == user }
          res = (join and join.notified_last_change?)
        end

        return res
      end

      ###
      # This method will mark this task as unread for any
      # setup watchers or task owners.
      # The exclude param should be a user or array of users whose unread
      # status will not be updated. For example, the person who wrote a
      # comment should probably be excluded.
      ###
      def mark_as_unread(exclude = [])
        exclude = [ exclude ].flatten.map { |e| e.id } # make sure it's an array.
        modify = self.assignments.select { |a| !exclude.include? a.user_id }.map { |a| a.unread = true }
        modify.map do |m|

        end
      end
      def mark_as_unread(exclude = [])
        exclude = [ exclude ].flatten # make sure it's an array.

        # TODO: if we merge owners and notifications into one table, should
        # clean this up.
        notifications = self.notifications + self.task_owners

        notifications.each do |n|
          n.update_attribute(:unread, true) if !exclude.include?(n.user)
        end
      end

      ###
      # Sets this task as read for user.
      # If read is passed, and false, sets the task
      # as unread for user.
      ###
      def set_task_read(user, read = true)
        # TODO: if we merge owners and notifications into one table, should
        # clean this up.
        notifications = self.notifications + self.task_owners

        user_notifications = notifications.select { |n| n.user == user }
        user_notifications.each do |n|
          n.update_attribute(:unread, !read)
        end
      end

      def unread?(user)
        num = TaskOwner.find_by_sql("select id, unread, task_id, user_id, count(*) as count 
        from task_owners 
        where task_owners.task_id = #{self.id} and task_owners.user_id = #{user.id} and task_owners.unread = true").first.attributes['count'].to_i
        num += Notification.find_by_sql("select count(*) as count 
        from notifications 
        where notifications.task_id = #{self.id} and notifications.user_id = #{user.id} and notifications.unread = true").first.attributes['count'].to_i
        return num > 0
      end
      
      ####
      ## Returns true if this task is marked as unread for user.
      ####
      #def unread?(user)
      #  # TODO: if we merge owners and notifications into one table, should
      #  # clean this up.
      #  notifications = self.notifications + self.task_owners
      #  unread = false

      #  user_notifications = notifications.select { |n| n.user == user }
      #  user_notifications.each do |n|
      #    unread ||= n.unread?
      #  end

      #  return unread
      #end
      

    end
  end
end
