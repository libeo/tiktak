class AddDefaultProjectForUser < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.integer :default_project_id
    end

  end

  def self.down
    change_table :users do |t|
      t.remove :default_project_id
    end
  end
end
