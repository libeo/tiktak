class CreateNoticeGroups < ActiveRecord::Migration
  def self.up
    create_table :notice_groups do |t|
      t.string :name
      t.integer :duration_format
      t.timestamps
    end

	create_table :notice_groups_users, :id => false do |t|
		t.integer :notice_group_id
		t.integer :user_id
	end

	create_table :notice_groups_projects, :id => false do |t|
		t.integer :notice_group_id
		t.integer :project_id
	end
  end

  def self.down
    drop_table :notice_groups
	drop_table :notice_groups_users
	drop_table :notice_groups_projects
  end
end
