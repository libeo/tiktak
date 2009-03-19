module CustomersHelper

  ###
  # Returns the html to link to a page to create a user
  # for the given customer
  ###
  def create_users_link(customer)
    url = {
      :controller => "users", 
      :action => "new", 
      :user => { :customer_id => @customer.id }
    }

    return link_to(_("Create User"), url)
  end
end
