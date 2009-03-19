module ResourcesHelper
  ###
  # Returns an array that can be used to select what the
  # type of a resource is.
  ###
  def resource_types_options_array
    current_user.company.resource_types.map { |rt| [rt.name, rt.id] }
  end

  ###
  # Returns the html to display the value for attribute.
  # If it is a password field, adds a link to request the
  # unencrypted password.
  ###
  def value_field(attribute, name_prefix, field_id, show_remove_link = false)
    type = attribute.resource_type_attribute

    if type.is_password? and !attribute.value.blank?
      res = "<div class=\"password\"></div>"
      url = show_password_resource_path(@resource, :attr_id => attribute.id)
      res += link_to(_("Show password"), url)
    else
      res = text_field_tag("#{ name_prefix }[value]", attribute.value, 
                           :id => field_id, :class => "value", 
                           :size => type.default_field_length)
    end

    if type.allows_multiple?
      add_style = show_remove_link ? "display: none" : ""
      remove_style = show_remove_link ? "" : "display: none;"

      res += link_to_function(_("Add"), "addAttribute(this)", 
                              :class => "add_attribute", 
                              :style => add_style)
      res += link_to_function(_("Remove"), "removeAttribute(this)", 
                              :class => "remove_attribute", 
                              :style => remove_style)
    end

    return res
  end

  ###
  # Returns only resources with no parent resource.
  ###
  def resources_without_parents(resources)
    resources.select do |r| 
      r.parent.nil? or !resources.include?(r.parent)
    end
  end

  ###
  # Returns all child resources of resource that should be shown.
  ###
  def child_resources(resource, all_visible_resources)
    resource.child_resources.select { |r| all_visible_resources.include?(r) }
  end

  ###
  # Returns the html to use to filter by resource types.
  ###
  def resource_type_filter
    values = current_user.company.resource_types
    values = values.map { |rt| [ rt.name, rt.id.to_s ] }
    
    selected = session[:resource_filters]
    selected = selected[:resource_type_id] if selected
    filter_for(:resource_type_id, values, selected)
  end

  ###
  # Returns the html to use to filter by customers
  ###
  def customer_filter
    customers = current_user.company.resources.map { |r| r.customer }
    customers.compact!
    customers = customers.map { |c| [ c.name, c.id.to_s ] }
    customers.uniq!

    selected = session[:resource_filters]
    selected = selected[:customer_id] if selected
    filter_for(:customer_id, customers, selected)
  end
end
