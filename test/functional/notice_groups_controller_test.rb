require 'test_helper'

class NoticeGroupsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:notice_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create notice_group" do
    assert_difference('NoticeGroup.count') do
      post :create, :notice_group => { }
    end

    assert_redirected_to notice_group_path(assigns(:notice_group))
  end

  test "should show notice_group" do
    get :show, :id => notice_groups(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => notice_groups(:one).to_param
    assert_response :success
  end

  test "should update notice_group" do
    put :update, :id => notice_groups(:one).to_param, :notice_group => { }
    assert_redirected_to notice_group_path(assigns(:notice_group))
  end

  test "should destroy notice_group" do
    assert_difference('NoticeGroup.count', -1) do
      delete :destroy, :id => notice_groups(:one).to_param
    end

    assert_redirected_to notice_groups_path
  end
end
