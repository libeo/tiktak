module ResourceTypesHelper
  ###
  # Returns the html to add an attribute to the currently shown
  # resource type.
  ###
  def add_attribute_link
    js = "appendPartial('/resource_types/attribute', '#resource_type_attributes')"
    link_to_function(_("Add another attribute"), js)
  end

end
