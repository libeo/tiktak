class TransfromTaskStatus < ActiveRecord::Migration
  def self.up

    Task.after_save.clear

    rename_column :tasks, :status, :status_id

    say "Adjusting statuses for all tasks"
    count = 1
    total = Task.count(:all)
    Task.all.each do |task|
      say "processing task #{task.id} (##{task.task_num}) (#{count} of #{total})"
      case task.status_id
      when 0, 1:
        cond = "name = 'Open'"
      when 2
        cond = "name = 'Closed'"
      when 3 
        cond = "Won't fix"
      when 4
        cond = "Invalid"
      when 5
        cond = "Duplicate"
      end
      task.status_id = task.company.statuses.find(:first, :conditions => cond)

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

    Task.after_save.clear

    in_progress = Status.create({:name => 'In Progress'})
    rename_column :tasks, :status_id, :status

  end

end
