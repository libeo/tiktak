class TransformDurations < ActiveRecord::Migration
  def self.up

    change_column_default(:tasks, :duration, 0)
    change_column_default(:tasks, :scheduled_duration, 0)
    add_column :tasks, :worked_seconds, :integer, :default => 0
    Task.find(:all, :select => 'id, duration, scheduled_duration, worked_minutes').each do |task|
      task.duration = task.duration * 60
      task.scheduled_duration = task.scheduled_duration * 60
      task.worked_seconds = task.worked_minutes * 60
      task.save(false)
    end
    remove_column :tasks, :worked_minutes
  end

  def self.down

    execute "alter table tasks alter duration drop default"
    execute "alter table tasks alter scheduled_duration drop default"
    add_column :tasks, :worked_minutes, :integer, :default => 0
    Task.find(:all, :select => 'id, duration, scheduled_duration, worked_seconds').each do |task|
      task.duration = task.duration / 60
      task.scheduled_duration = task.scheduled_duration / 60
      task.worked_seconds = task.worked_minutes / 60
      task.save(false)
    end
    remove_column :tasks, :worked_seconds

  end
end
