require File.dirname(__FILE__) + '/../test_helper'

class ResourceTypesControllerTest < ActionController::TestCase
  fixtures :companies, :users

  def setup
    login
    user = @user
    user.use_resources = true
    user.save!

    company = user.company
    @type = company.resource_types.build(:name => "test")
    @type.new_type_attributes = [ { :name => "a1" }, { :name => "a2" } ]
    @type.save!

    @resource = company.resources.build(:name => "test res")
    @resource.resource_type = @type
  end

  test "all should redirect if not admin set on user" do
    user = User.find(@request.session[:user_id])
    user.admin = false
    user.save!

    end_page = { :controller => "activities", :action => "list" }

    get :new
    assert_redirected_to(end_page)

    get :edit, :id => @type.id
    assert_redirected_to(end_page)

    post :create, :id => @type.id
    assert_redirected_to(end_page)

    post :update, :id => @type.id
    assert_redirected_to(end_page)

    post :destroy, :id => @type.id
    assert_redirected_to(end_page)
  end 


end
