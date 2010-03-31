class Task
  # Module that regroups all functions dealing with task properties and task property values
  # Task properties are either standard (type,status,priority,severity) properties 
  # or custom properties added to the company. 
  module TaskProperties
    augmentation do

      # Sets up custom properties using the given form params
      # TODO: document how to pass params
      def properties=(params)
        task_property_values.clear

        params.each do |prop_id, val_id|
          next if val_id.blank?
          task_property_values.build(:property_id => prop_id, :property_value_id => val_id)
        end
      end

      # Sets up a custom property and its value
      # TODO: document how to pass properties and values
      def set_property_value(property, property_value)
        # remove the current one if it exists
        existing = task_property_values.detect { |tpv| tpv.property == property }
        if existing and existing.property_value != property_value
          task_property_values.delete(existing)
        end

        if property_value
          # only create a new one if property_value is set
          task_property_values.create(:property_id => property.id, :property_value_id => property_value.id)
        end
      end

      # Returns the value of the given property for this task
      # TODO: document what the argument 'property' represents
      def property_value(property)
        return unless property

        tpv = task_property_values.detect { |tpv| tpv.property.id == property.id }
        tpv.property_value if tpv
      end

      ###
      # This method will help in the migration of type id, priority and severity
      # to use properties. It can be removed once that is done.
      # TODO: check if I can remove it
      ###
      def convert_attributes_to_properties(type, priority, severity)
        old_value = Task.issue_types[attributes['type_id'].to_i]
        copy_task_value(old_value, type)

        old_value = Task.priority_types[attributes['priority'].to_i]
        copy_task_value(old_value || 0, priority)

        old_value = Task.severity_types[attributes['severity_id'].to_i]
        copy_task_value(old_value || 0, severity)
      end

      ###
      # This method will help in the migration of type id, priority and severity
      # to use properties. It can be removed once that is done.
      # TODO: check if I can remove it
      #
      # Copies the severity, priority etc on the given task to the new
      # property.
      ###
      def copy_task_value(old_value, new_property)
        return if !old_value

        matching_value = new_property.property_values.detect { |pv| pv.value == old_value }
        set_property_value(new_property, matching_value) if matching_value
      end

      ###
      # This method will help in the rollback of type, priority and severity 
      # from properties.
      # It can be removed after.
      # TODO: check if I can remove it
      ###
      def convert_properties_to_attributes
        type = company.properties.detect { |p| p.name == "Type" }
        severity = company.properties.detect { |p| p.name == "Severity" }
        priority = company.properties.detect { |p| p.name == "Priority" }

        self.type_id = Task.issue_types.index(property_value(type).to_s)
        self.severity_id = Task.severity_types.invert[property_value(severity).to_s] || 0
        self.priority = Task.priority_types.invert[property_value(priority).to_s] || 0
      end

      ###
      # These methods replace the columns for these values. If people go ahead
      # and change the default priority, etc values then they will return a 
      # default value that shouldn't affect sorting.
      ###
      def priority
        property_value_as_integer(company.priority_property, Task.priority_types.invert) || 0
      end  
      def severity_id
        property_value_as_integer(company.severity_property, Task.severity_types.invert) || 0
      end
      def type_id
        property_value_as_integer(company.type_property) || 0
      end

      ###
      # Returns an int representing the given property.
      # Pass in a hash of strings to ids to return those values, otherwise
      # the index in the property value list is returned.
      ###
      def property_value_as_integer(property, mappings = {})
        task_value = property_value(property)

        if task_value
          return mappings[task_value.value] || property.property_values.index(task_value)
        end
      end
     
      ###
      # A task is critical if it is in the top 20% of the possible
      # ranking using the companys sort.
      ###
      def critical?
        return false if company.maximum_sort_rank == 0

        sort_rank.to_f / company.maximum_sort_rank.to_f > 0.80
      end

      ###
      # A task is normal if it is not critical or low.
      ###
      def normal?
        !critical? and !low?
      end

      ###
      # A task is low if it is in the bottom 20% of the possible
      # ranking using the companys sort.
      ###
      def low?
        return false if company.maximum_sort_rank == 0

        sort_rank.to_f / company.maximum_sort_rank.to_f < 0.20
      end

      # String representing the task type
      # (task, new feature, defect, improvement)
      def issue_type
        Task.issue_types[self.type_id.to_i]
      end

      # Array of possible task types (issues)
      def self.issue_types
        ["Task", "New Feature", "Defect", "Improvement"]
      end

      # String representing the task status
      # (open, in progress, closed, won't fix, invalid, duplicate)
      def status_type
        Task.status_types[self.status]
      end

      # String representing a certain task status
      # type : integer, task status
      def self.status_type(type)
        Task.status_types[type]
      end

      # Array of possible task statuses
      def self.status_types
        ["Open", "In Progress", "Closed", "Won't fix", "Invalid", "Duplicate"]
      end

      # String representing the task priority
      # (Lowest, low, normal, high, urgent, critical)
      def priority_type
        Task.priority_types[self.priority]
      end

      # Hash of task priorities.
      # keys : numerical representation, ranging from -2 to 3, of the priority. 
      # Highest is more critical.
      # values : String representation of the priority
      def self.priority_types
        {  -2 => "Lowest", -1 => "Low", 0 => "Normal", 1 => "High", 2 => "Urgent", 3 => "Critical" }
      end

      # String representing the task severity
      # (trivial, minor, normal, major, cirical, blocker)
      def severity_type
        Task.severity_types[self.severity_id]
      end

      # Hash of task severities
      # keys : numerical representation, ranging from -2 to 3, of the severity. 
      # Highest is more severe
      # values : String representation of the severity
      def self.severity_types
        { -2 => "Trivial", -1 => "Minor", 0 => "Normal", 1 => "Major", 2 => "Critical", 3 => "Blocker"}
      end
      
    end
  end
end
