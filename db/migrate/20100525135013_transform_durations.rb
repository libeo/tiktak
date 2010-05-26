class TransformDurations < ActiveRecord::Migration
  def self.up

    change_column_default(:tasks, :duration, 0)
    change_column_default(:tasks, :scheduled_duration, 0)
    add_column :tasks, :worked_seconds, :integer, :default => 0

    Task.reset_column_information
    Task.after_save.clear

    say "adjusting durations in tasks"
    total = Task.count(:all)
    count = 1
    Task.all.each do |task|
      say "processing task #{task.id} (##{task.task_num}) (#{count} out of #{total})"
      task.duration = 0 if task.duration.nil?
      task.duration = task.duration * 60
      task.scheduled_duration = task.scheduled_duration * 60
      task.worked_seconds = task.worked_minutes * 60
      task.save(false)
      count += 1
    end
    remove_column :tasks, :worked_minutes

    say "adjusting durations in users"
    User.all.each do |user|
      user.workday_duration = user.workday_duration * 60
      user.save(false)
    end

  end

  def self.down

    execute "alter table tasks alter duration drop default"
    execute "alter table tasks alter scheduled_duration drop default"
    add_column :tasks, :worked_minutes, :integer, :default => 0

    Task.reset_column_information
    Task.after_save.clear

    say "adjusting durations in tasks"
    total = Task.count(:all)
    count = 1
    Task.all.each do |task|
      say "processing task #{task.id} (##{task.task_num}) (#{count} out of #{total})"
      task.duration = task.duration / 60
      task.scheduled_duration = task.scheduled_duration / 60
      task.worked_seconds = task.worked_minutes / 60
      task.save(false)
      count += 1
    end
    remove_column :tasks, :worked_seconds

    say "adjusting durations in users"
    User.find(:all, :select => 'id, workday_duration').each do |user|
      user.workday_duration = user.workday_duration / 60
      user.save(false)
    end

  end
end
