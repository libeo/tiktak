class FixFieldsForNewVersion < ActiveRecord::Migration
  def self.up
    change_table :tasks do |t|
      t.remove :priority
      t.remove :severity_id
      t.remove :type_id
    end

    change_table :views do |t|
      t.remove :filter_tags
    end

    drop_table :tags
    drop_table :task_tags


    say "Adjusting statuses for all tasks"
    count = 0
    total = Task.count(:all)
    Task.all.each do |task|
      say "processing task #{task.id} (##{task.task_num}) (#{count} of #{total})"
      task.status = task.status - 1
      task.completed_at = Time.now.utc if task.status > 0 and task.completed_at.nil?
      task.save(false)
    end

  end

  def self.down
    change_table :tasks do |t|
      t.integer :priority, :default => 0
      t.integer :severity_id, :default => 0
      t.integer :type_id, :default => 0
    end

    change_table :views do |t|
      t.string :filter_tags, :default => ""
    end

    create_table "tags" do |t|
      t.integer "company_id"
      t.string  "name"
    end

    create_table "task_tags", :id => false do |t|
      t.integer "tag_id"
      t.integer "task_id"
    end

    say "Adjusting statuses for all tasks"
    count = 0
    total = Task.count(:all)
    Task.all.each do |task|
      say "processing task #{task.id} (##{task.task_num}) (#{count} of #{total})"
      task.status = task.status + 1
      task.save(false)
    end

  end

end
