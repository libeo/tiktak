###
# A TaskPropertyValue links a task with a particular property
# and a value for that property.
###
class TaskPropertyValue < ActiveRecord::Base
  belongs_to :task
  belongs_to :property
  belongs_to :property_value

  accepts_nested_attributes_for :property_value

end
