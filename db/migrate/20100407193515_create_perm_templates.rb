class CreatePermTemplates < ActiveRecord::Migration
  def self.up
    create_table :perm_templates do |t|
      t.boolean  "can_comment",    :default => true
      t.boolean  "can_work",       :default => true
      t.boolean  "can_report",     :default => true
      t.boolean  "can_close",      :default => true
      t.boolean  "can_create",     :default => false
      t.boolean  "can_edit",       :default => false
      t.boolean  "can_reassign",   :default => false
      t.boolean  "can_prioritize", :default => false
      t.boolean  "can_grant",      :default => false
      t.boolean  "can_milestone",  :default => false
      t.timestamps
      t.references :user
      t.references :company
    end

    User.find(:all, :conditions => 'create_projects = true').each do |user|
      PermTemplate.create({:user_id => user.id, :company_id => user.company_id})
    end

  end

  def self.down
    drop_table :perm_templates
  end
end
