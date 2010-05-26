class TransfromTaskStatus < ActiveRecord::Migration
  def self.up

    Task.after_save.clear

    rename_column :tasks, :status, :status_id
    
    Task.reset_column_information

    say "Adjusting statuses for all tasks"
    count = 1
    total = Task.count(:all)
    Task.all.each do |task|
      say "processing task #{task.id} (##{task.task_num}) (#{count} of #{total})"
      case task.status_id
      when 0
        cond = "name = 'Open'"
      when 1
        cond = "name = 'Open'"
      when 2
        cond = "name = 'Closed'"
      when 3
        cond = "name = \"Won't fix\""
      when 4
        cond = "name = 'Invalid'"
      when 5
        cond = "name = 'Duplicate'"
      end
      s = task.company.statuses.find(:first, :conditions => cond)
      task.status_id = s.id

      task.completed_at = Time.now.utc if task.status.name != "Open"
      task.save(false)
      count += 1
    end

    say "removing unused task qualifiers"
    TaskFilterQualifier.all(:conditions => ["task_filter_qualifiers.qualifiable_type = 'status' and statuses.name = 'In Progress'"], :joins => "left outer join statuses on statuses.id = task_filter_qualifiers.qualifiable_id").each do |tf|
      tf.destroy
    end

    say "removing unused statuses"
    Status.destroy_all({:name => "In Progress"})

  end

  def self.down

    Task.after_save.clear

    Company.all.each do |c|
      c.statuses.create({:name => 'In Progress'})
    end
    rename_column :tasks, :status_id, :status

  end

end
