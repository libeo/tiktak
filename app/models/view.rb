# A saved filter which can be applied to a group of tasks

class View < ActiveRecord::Base

  belongs_to :user
  belongs_to :company

  has_and_belongs_to_many :property_values, :join_table => "views_property_values"

  ###
  # Sets any property values to use as filters on this view.
  ###
  def properties=(params)
    property_values.clear

    all_properties = Property.all_for_company(company)

    params.each do |property_value_id|
      next if property_value_id.blank?

      pv = PropertyValue.find(property_value_id)
      if all_properties.index(pv.property)
        property_values << pv
      end
    end
  end
  
  ###
  # Returns the selected property value on this view for property.
  # (Or nil if none)
  ###
  def selected(property)
    property.property_values.detect { |pv| self.property_values.index(pv) }
  end

  ###
  # This method will help in the migration of type id, priority and severity
  # to use properties. It can be removed once that is done.
  ###
  def convert_attributes_to_properties
    all_properties = Property.all_for_company(company)
    new_ids = []

    type = all_properties.detect { |t| t.name == "Type" }
    old = Task.issue_types[filter_type_id]
    new_ids << type.property_values.detect { |p| p.to_s == old }
    
    priority = all_properties.detect { |t| t.name == "Priority" }
    old = Task.priority_types[filter_priority]
    new_ids << priority.property_values.detect { |p| p.to_s == old }

    severity = all_properties.detect { |t| t.name == "Severity" }
    old = Task.severity_types[filter_severity]
    new_ids << severity.property_values.detect { |p| p.to_s == old }

    self.properties = new_ids
  end

  ###
  # This method will migrate type id, priority and severity back from 
  # the properties to attributes.
  # It can be removed if we're happy with the migration to properties.
  ###
  def convert_properties_to_attributes
    all_properties = Property.all_for_company(company)
    
    type = all_properties.detect { |t| t.name == "Type" }
    old_id = Task.issue_types.index(selected(type).to_s)
    self.filter_type_id = old_id

    priority = all_properties.detect { |t| t.name == "Priority" }
    old_id = Task.priority_types.invert[selected(priority).to_s]
    self.filter_priority = old_id

    severity = all_properties.detect { |t| t.name == "Severity" }
    old_id = Task.severity_types.invert[selected(severity).to_s]
    self.filter_severity = old_id

    save
  end
end
