module CustomAttributesHelper

  ###
  # Returns a link that will add a new attribute and fields to edit it
  # to the current page.
  ###
  def link_to_add_attribute
    js = "appendPartial('/custom_attributes/fields', '#attributes')"
    link_to_function(_("Add another attribute"), js, :class => "add_attribute")
  end

  ###
  # Returns the form field prefix to use for the given attribute
  ###
  def prefix(attribute)
     prefix = "custom_attributes"
     prefix = "new_#{ prefix }" if attribute.nil? or attribute.new_record? 
    
    return prefix
  end

  ###
  # Returns the form field prefix to use for the given choice
  ###
  def choice_prefix(choice, attribute)
    res = prefix(attribute)
    res += "[#{ attribute.id }][choice_attributes][#{ choice.id.to_i }]"

    return res
  end

  ###
  # Returns a link that will add a new choice to attribute and display 
  # it in the current page.
  ###
  def add_choice_link(attribute)
    display = attribute.preset? ? "" : "none"
    link_to_function(_("Add a choice"), "addAttributeChoices(this)", :class => "add_choice_link right_link", :style => "display: #{ display }")
  end

end
