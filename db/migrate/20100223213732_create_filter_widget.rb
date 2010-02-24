class CreateFilterWidget < ActiveRecord::Migration
  def self.up
    add_column :task_filters, :filter_id, :integer
  end

  def self.down
    remove_column :task_filters, :filter_id
  end
end
