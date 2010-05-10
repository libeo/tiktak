class MergeTaskOwnersAndNotifications < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.integer :task_id
      t.integer :user_id
      t.boolean :assigned, :default => true
      t.boolean :notified, :default => true
      t.boolean :bookmarked, :default => false
    end

    Assignment.reset_column_information

    say "Merging task_owners and notifications into assignments"
    total = Task.count
    counter = 1
    Task.all(:select => 'id, task_num').each do |task|

      say_with_time "Processing task #{task.id} (##{task.task_num}) (#{counter} out of #{total})" do 

        owners = TaskOwner.all(:conditions => ["task_id = ?", task.id])
        notifications = Notification.all(:conditions => ["task_id = ?", task.id])
        n_ids = notifications.map { |n| n.user_id }

        new = []
        owners.each do |owner|
          if n_ids.include? owner.user_id
            e = owner.attributes.merge({'assigned' => true, 'notified' => true})
          else
            e = owner.attributes.merge({'assigned' => true, 'notified' => false})
          end
          notifications = notifications.delete_if { |n| n.user_id == owner.user_id }
          e.delete 'id'
          e['bookmarked'] = e['unread']
          e.delte 'unread'
          new << e
        end

        notifications.each do |n|
          new << n.attributes.merge({'assigned' => false, 'notified' => true})
        end

        Assignment.create(new)

      end
      counter += 1

    end

    drop_table :task_owners
    drop_table :notifications
  end

  def self.down

    create_table "notifications" do |t|
      t.integer "task_id"
      t.integer "user_id"
      t.boolean "unread",               :default => false
      t.boolean "notified_last_change", :default => true
    end

    create_table "task_owners" do |t|
      t.integer "user_id"
      t.integer "task_id"
      t.boolean "unread",               :default => false
      t.boolean "notified_last_change", :default => true
    end

    TaskOwner.reset_column_information
    Notification.reset_column_information

    say "Converting assignments into task_owners and notifications"
    total = Assignment.count
    counter = 1
    Assignment.all.each do |assignment|
      values = assignment.attributes.dup
      values.delete 'assigned'
      values.delete 'notified'

      if assignment.assigned?
        TaskOwner.create(values)
      end
      if assignment.notified?
        Notification.create(values)
      end
      say "converted assignment #{assignment.id} (#{counter} of #{total})"
    end

    drop_table :assignments
  end
end
