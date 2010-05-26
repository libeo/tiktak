class Status < ActiveRecord::Base
  belongs_to :company
  validates_presence_of :company

  named_scope :open, :conditions => 'name = "Open"'
  named_scope :closed, :conditions => 'name != "Open"'

  # Creates the default statuses expected in the system 
  def self.create_default_statuses(company)
    company.statuses.build(:name => "Open").save!
    company.statuses.build(:name => "Closed").save!
    company.statuses.build(:name => "Won't fix").save!
    company.statuses.build(:name => "Invalid").save!
    company.statuses.build(:name => "Duplicate").save!
  end

  def to_s
    name
  end

end
