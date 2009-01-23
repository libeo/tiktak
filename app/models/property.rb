###
# Properties are used to describe tasks. Each property has a number of 
# PropertyValues which define the values available for the user to choose
# from.
#
# Properties can be created and edited by users in the system and so can 
# have any PropertyValues a user needs.

# Examples of potential properties include Priority, Status, Sub-project
# - anything that suits a company's workflow..
###
class Property < ActiveRecord::Base
  belongs_to :company
  has_many :property_values, :order => "position asc, id asc", :dependent => :destroy
  
  after_save :clear_other_default_colors
  before_destroy :remove_invalid_task_property_values
  
  # Returns an array of the default values that should be
  # used when creating a new company.
  def self.defaults
    res = []
    res << [ { :name => _("Type") },
             [ { :value => _("Task"),        :icon_url => "/images/task_icons/task.png" },
               { :value => _("New Feature"), :icon_url => "/images/task_icons/new_feature.png" },
               { :value => _("Defect"),      :icon_url => "/images/task_icons/bug.png" },
               { :value => _("Improvement"), :icon_url => "/images/task_icons/change.png" }
             ]]
    res << [ { :name => _("Priority"), :default_sort => true, :default_color => true },
             [ { :value => _("Critical"), :color => "#FF6666" },
               { :value => _("Urgent"),   :color => "#FF6666" },
               { :value => _("High"),     :color => "#F2AB99" },
               { :value => _("Normal"),   :color => "#B0D295" },
               { :value => _("Low"),      :color => "#F3F3F3" },
               { :value => _("Lowest"),   :color => "#F3F3F3" }
             ]]
    res << [ { :name => _("Severity"), :default_sort => true },
             [ { :value => _("Blocker") },
               { :value => _("Critical") },
               { :value => _("Major") },
               { :value => _("Normal") },
               { :value => _("Minor") },
               { :value => _("Trivial") }
             ]]

    return res
  end

  ###
  # Returns an array of all properties for company which
  # have colors set up for their property values.
  ###
  def self.all_with_colors(company)
    props = company.properties.select do |p|
      p.property_values.detect { |pv| !pv.color.blank? }
    end

    return props
  end

  ###
  # Returns an array of all properties for company which
  # have icons set up for their property values.
  ###
  def self.all_with_icons(company)
    props = company.properties.select do |p|
      p.property_values.detect { |pv| !pv.icon_url.blank? }
    end

    return props
  end

  ###
  # Finds the property matching the given group_by parameter.
  ###
  def self.find_by_group_by(company, group_by)
    return if !group_by

    # N.B. This is mainly used in task filtering in the list view.
    match = group_by.match(/property_(\d+)/)
    return company.properties.find(match[1]) if match
  end

  ###
  # Returns a name suitable for use as a div id or similar.
  ###
  def filter_name
    @filter_name ||= "property_#{ id }"
  end

  def to_s
    name
  end

  ###
  # Clears any tasks which have a value for this 
  # property set.
  ###
  def remove_invalid_task_property_values
    tpvs = TaskPropertyValue.find(:all, :conditions => { :property_id => id })
    tpvs.each { |tpv| tpv.destroy }
  end

  ###
  # Only one property can be used to color tasks, so this
  # method will ensure only one property will have the 
  # default_colors attribute set.
  ###
  def clear_other_default_colors
    if self.default_color
      other_properties = company.properties - [ self ]
      other_properties.each do |p|
        if p.default_color
          p.default_color = false
          p.save
        end
      end
    end
  end
end
