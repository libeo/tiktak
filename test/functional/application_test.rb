require File.dirname(__FILE__) + '/../test_helper'

class ApplicationControllerText < ActionController::TestCase
  fixtures :users, :companies, :customers, :tasks, :projects, :milestones, :work_logs
  
  def setup
     use_controller ActivitiesController

     @request.with_subdomain('cit')
     @request.session[:user_id] = users(:admin).id
  end

  test "should get current_user" do
     get :index
     @controller.current_user.should.equal(users(:admin))
  end

  test "user 1 should be admin" do
     get :index
     assigns(:current_user).admin?.should.be true
  end

  test "user 2 should NOT be admin" do
     @request.session[:user_id] = users(:fudge).id
     get :index
     assigns(:current_user).admin?.should.be false
  end

  test "should get all online users" do
     get :index
     @controller.current_users.size.should.be 2
  end

  test "parse_time should handle 1w2d3h4m" do
     get :index
     @controller.parse_time("1w2d3h4m").should.be(200040)
     @controller.parse_time("4m").should.be(240)
     @controller.parse_time("1d").should.be(27000)
  end

  test "setup_task_filters should work for single selects" do
    property = users(:admin).company.properties.first
    
    params = {
      :filter_status => 2,
      :filter_type => "-1",
      property.filter_name => property.property_values.first.id
    }

    get :setup_task_filters, params.merge(:redirect_action => "index")

    assert_equal "0", session[:filter_customer]
    assert_equal "0", session[:filter_milestone]
    assert_equal "2", session[:filter_status]
    assert_equal(property.property_values.first.id.to_s, 
                 session[property.filter_name])
  end

  test "setup_task_filters should work for task,milestone,project filters" do    
    params = { :redirect_action => "index" }

    get :setup_task_filters, params.merge(:filter => "p123")
    assert_equal [], session[:filter_customer]
    assert_equal [], session[:filter_milestone]
    assert_equal ["123"], session[:filter_project]

    get :setup_task_filters, params.merge(:filter => "u5000")
    assert_equal [], session[:filter_customer]
    assert_equal [-5001], session[:filter_milestone]
    assert_equal [], session[:filter_project]

    get :setup_task_filters, params.merge(:filter => "m45")
    assert_equal [], session[:filter_customer]
    assert_equal ["45"], session[:filter_milestone]
    assert_equal [],  session[:filter_project]

    get :setup_task_filters, params.merge(:filter => "c1")
    assert_equal ["1"], session[:filter_customer]
    assert_equal [], session[:filter_milestone]
    assert_equal [], session[:filter_project]
  end
  
end
