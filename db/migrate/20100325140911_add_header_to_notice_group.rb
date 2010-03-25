class AddHeaderToNoticeGroup < ActiveRecord::Migration
  def self.up
    change_table :notice_groups do |t|
      t.string :message_subject, :default => ""
      t.text :message_header, :default => ""
    end
  end

  def self.down
    remove_column :notice_groups, :message_subject
    remove_column :notice_groups, :message_header
  end
end
