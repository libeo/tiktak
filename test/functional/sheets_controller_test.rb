require 'test_helper'

class SheetsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sheets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sheet" do
    assert_difference('Sheet.count') do
      post :create, :sheet => { }
    end

    assert_redirected_to sheet_path(assigns(:sheet))
  end

  test "should show sheet" do
    get :show, :id => sheets(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => sheets(:one).to_param
    assert_response :success
  end

  test "should update sheet" do
    put :update, :id => sheets(:one).to_param, :sheet => { }
    assert_redirected_to sheet_path(assigns(:sheet))
  end

  test "should destroy sheet" do
    assert_difference('Sheet.count', -1) do
      delete :destroy, :id => sheets(:one).to_param
    end

    assert_redirected_to sheets_path
  end
end
