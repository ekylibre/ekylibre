require 'test_helper'

class MockedUser < Struct.new("MockedUser", :name, :comment)
  
end

class UserTest < ActionController::IntegrationTest
  fixtures :all

  context "A valid user" do
    setup do
      @user = MockedUser.new('gendo', 'secret') # users(:users_001)
      @company = companies(:companies_001)
    end
    
    should "login" do
      get "session/new"
      assert_response :success
      post "session", :name=>@user.name, :password=>@user.comment
      assert_response :redirect
    end

    context "which is logged in" do

      setup do
        get "session/new"
        assert_response :success
        post "session", :name=>@user.name, :password=>@user.comment
        assert_redirected_to :controller=>:dashboards, :action=>:general, :company=>@company.code
      end

      should "change its password" do 
        get "#{@company.code}/me/change_password"
        assert_response :success
        post "#{@company.code}/me/change_password", :user=>{:old_password=>@user.comment, :password=>"abcdefgh", :password_confirmation=>"abcdefgh"}
        assert_response :redirect
        delete "session"
        assert_response :redirect
        post "session", :name=>@user.name, :password=>"abcdefgh"
        assert_redirected_to :controller=>:dashboards, :action=>:general, :company=>@company.code
        get "#{@company.code}/me/change_password"
        assert_response :success
        post "#{@company.code}/me/change_password", :user=>{:old_password=>"abcdefgh", :password=>@user.comment, :password_confirmation=>@user.comment}
        assert_response :redirect
      end

    end

  end


  context "An unknown user" do
    
    should "register a new company" do
      get "company/register"
      assert_response :success
      post "company/register", :my_company=>{:name=>"My Company LTD", :code=>"mcltd"}, :user=>{:last_name=>"Company", :first_name=>"My", :name=>"my", :password=>"12345678", :password_confirmation=>"12345678"}
      assert_redirected_to :controller=>:dashboards, :action=>:welcome, :company=>"mcltd"
    end

    should "register a new company with english data" do
      get "company/register"
      assert_response :success
      post "company/register", :my_company=>{:name=>"My Company LTD", :code=>"mcltd"}, :user=>{:last_name=>"Company", :first_name=>"My", :name=>"my", :password=>"12345678", :password_confirmation=>"12345678"}, :demo=>"eng"
      assert_redirected_to :controller=>:dashboards, :action=>:welcome, :company=>"mcltd"
    end

    should "register a new company with french data" do
      get "company/register"
      assert_response :success
      post "company/register", :my_company=>{:name=>"My Company LTD", :code=>"mcltd"}, :user=>{:last_name=>"Company", :first_name=>"My", :name=>"my", :password=>"12345678", :password_confirmation=>"12345678"}, :demo=>"fra"
      assert_redirected_to :controller=>:dashboards, :action=>:welcome, :company=>"mcltd"
    end

  end



end
