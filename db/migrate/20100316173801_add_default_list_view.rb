class AddDefaultListView < ActiveRecord::Migration
  def self.up
    add_column :users, :default_list_view, :string, :default => 'list_new'
  end

  def self.down
    remove_column :users, :default_list_view
  end
end
