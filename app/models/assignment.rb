class Assignment < ActiveRecord::Base
  belongs_to :user
  belongs_to :task

  named_scope :unread, :conditions => { :unread => true }

  #validates_presence_of :user_id, :message => 'No user defined for assignment'
  #validates_presence_of :task_id, :message => 'No task defined for assignment'
end
