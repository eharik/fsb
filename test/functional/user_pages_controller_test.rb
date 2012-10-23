require 'test_helper'

class UserPagesControllerTest < ActionController::TestCase
  test "should get signIn" do
    get :signIn
    assert_response :success
  end

  test "should get signUp" do
    get :signUp
    assert_response :success
  end

  test "should get home" do
    get :home
    assert_response :success
  end

  test "should get editProfile" do
    get :editProfile
    assert_response :success
  end

end
