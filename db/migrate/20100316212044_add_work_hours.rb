class AddWorkHours < ActiveRecord::Migration
  def self.up
    add_column :users, :work_hours, :float, :default => 75.0
    change_column :companies, :payperiod_date, :datetime
  end

  def self.down
    remove_column :users, :work_hours
    change_column :companies, :payperiod_date, :datetime
  end
end
