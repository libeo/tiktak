class GregRandomStuff < ActiveRecord::Migration
  def self.up
    change_table :companies do |t|
      t.date :payperiod_date
      t.integer :payperiod_days, :default => 7
    end
  end

  def self.down
    change_table :companies do |t|
      t.remove :payperiod_date
      t.remove :payperiod_days
    end
  end
end
