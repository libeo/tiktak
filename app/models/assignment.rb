class Assignment < ActiveRecord::Base
  belongs_to :user
  belongs_to :task

  named_scope :unread, :conditions => { :unread => true }
end
