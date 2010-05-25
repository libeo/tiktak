class TransfromTaskStatus < ActiveRecord::Migration
  def self.up

    rename_column :tasks, :status, :status_id
    open = Status.first(:conditions => 'name = "Open"')
    in_progress = Status.first(:conditions => 'name = "In Progress"')

    say "Adjusting statuses for all tasks"
    count = 1
    total = Task.count(:all)
    Task.all.each do |task|
      say "processing task #{task.id} (##{task.task_num}) (#{count} of #{total})"
      if task.status_id <= 1
        task.status_id = open.id
      end
      task.completed_at = Time.now.utc if task.status_id != open.id and task.completed_at.nil?
      task.save(false)
      count += 1
    end

    say "removing unused task qualifiers"
    TaskFilterQualifier.all(:conditions => ["qualifiable_type = 'status' and qualifiable_id = ?", in_progress.id]).each do |tf|
      tf.destroy
    end

    say "removing unused statuses"
    in_progress.destroy

  end

  def self.down

    in_progress = Status.create({:name => 'In Progress'})
    rename_column :tasks, :status_id, :status

  end

end
