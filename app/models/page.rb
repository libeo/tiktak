class Page < ActiveRecord::Base
  belongs_to    :company
  belongs_to    :project
  belongs_to    :user

  acts_as_list  :scope => :project

  validates_presence_of :name
  validates_presence_of :project
end
