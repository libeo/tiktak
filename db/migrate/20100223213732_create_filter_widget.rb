class CreateFilterWidget < ActiveRecord::Migration
  def self.up
    add_column :widgets, :filter_id, :integer
  end

  def self.down
    remove_column :widgets, :filter_id
  end
end
