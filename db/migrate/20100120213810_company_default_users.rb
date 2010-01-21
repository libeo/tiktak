class CompanyDefaultUsers < ActiveRecord::Migration
  def self.up
    create_table :default_user_permissions do |t|
      t.integer :user_id
      t.integer :company_id
      t.boolean  "can_comment",    :default => false
      t.boolean  "can_work",       :default => false
      t.boolean  "can_report",     :default => false
      t.boolean  "can_create",     :default => false
      t.boolean  "can_edit",       :default => false
      t.boolean  "can_reassign",   :default => false
      t.boolean  "can_prioritize", :default => false
      t.boolean  "can_close",      :default => false
      t.boolean  "can_grant",      :default => false
      t.boolean  "can_milestone",  :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :default_user_permissions
  end
end
