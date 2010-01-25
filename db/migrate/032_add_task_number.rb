class AddTaskNumber < ActiveRecord::Migration
  def self.up

    add_column :tasks, :task_num, :integer, :default => 0

    companies = Company.find(:all)
    companies.each do |c|
      say "Handling #{c.name}:"
      tasks = Task.find(:all, :conditions => ["company_id = ?", c.id], :order => "id")
      tasks.each do |t|
        t.task_num = Task.maximum('task_num', :conditions => ["company_id = ?", c.id]) + 1
        say "#{t.name}: #{t.task_num.to_s}", true
        t.save
      end
    end

  end

  def self.down
    remove_column :tasks, :task_num
  end
end
