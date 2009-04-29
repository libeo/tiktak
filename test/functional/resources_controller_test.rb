require File.dirname(__FILE__) + '/../test_helper'

class ResourcesControllerTest < ActionController::TestCase
  fixtures :companies, :users

  def setup
    @request.with_subdomain("cit")
    user = users(:admin)
    user.use_resources = true
    user.save!
    @request.session[:user_id] = user.id

    company = user.company
    @type = company.resource_types.build(:name => "test")
    @type.new_type_attributes = [ { :name => "a1" }, { :name => "a2" } ]
    @type.save!

    customer = company.customers.build(:name => "test cust")
    customer.save!

    @resource = company.resources.build(:name => "test res")
    @resource.resource_type = @type
    @resource.customer = customer
  end

  test "all should redirect if not use_resources set on user" do
    user = User.find(@request.session[:user_id])
    user.use_resources = false
    user.save!

    end_page = { :controller => "activities", :action => "list" }

    get :new
    assert_redirected_to(end_page)

    get :edit, @resource.id
    assert_redirected_to(end_page)

    post :create, @resource.id
    assert_redirected_to(end_page)

    post :update, @resource.id
    assert_redirected_to(end_page)

    post :destroy, @resource.id
    assert_redirected_to(end_page)
  end 

  test "/new should render :success" do
    get :new
    assert_response :success
  end

  test "/edit should render :success" do
    assert @resource.save
    get :edit, :id => @resource.id

    assert_response :success
  end

  test "/index should render :success" do
    assert @resource.save

    get :index
    assert_response :success

    resources = assigns["resources"]
    assert resources.length > 0
  end
end
