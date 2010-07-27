require 'test_helper'

class UserTest < ActionController::IntegrationTest
  fixtures :all

  context "A valid user" do
    setup do
      @user = users(:users_001)
      @company = companies(:companies_001)
    end
    
    should "login" do
      get "authentication/login"
      assert_response :success
      post "authentication/login", :name=>@user.name, :password=>@user.comment
      assert_response :redirect
    end

    context "which is logged in" do

      setup do
        get "authentication/login"
        assert_response :success
        post "authentication/login", :name=>@user.name, :password=>@user.comment
        assert_redirected_to :controller=>:company, :action=>:index, :company=>@company.code
      end

      should "change its password" do 
        get "#{@company.code}/company/change_password"
        assert_response :success
        post "#{@company.code}/company/change_password", :user=>{:old_password=>@user.comment, :password=>"abcdefgh", :password_confirmation=>"abcdefgh"}
        assert_response :redirect
        get "authentication/logout"
        assert_response :redirect
        post "authentication/login", :name=>@user.name, :password=>"abcdefgh"
        assert_redirected_to :controller=>:company, :action=>:index, :company=>@company.code
        get "#{@company.code}/company/change_password"
        assert_response :success
        post "#{@company.code}/company/change_password", :user=>{:old_password=>"abcdefgh", :password=>@user.comment, :password_confirmation=>@user.comment}
        assert_response :redirect
      end

    end

  end


  context "An unknown user" do
    
    should "register a new company" do
      get "authentication/register"
      assert_response :success
      post "authentication/register", :company=>{:name=>"My Company LTD", :code=>"mcltd"}, :user=>{:last_name=>"Company", :first_name=>"My", :name=>"my", :password=>"12345678", :password_confirmation=>"12345678"}
      assert_redirected_to :controller=>:company, :action=>:welcome, :company=>"mcltd"
    end

    should "register a new company with data" do
      get "authentication/register"
      assert_response :success
      post "authentication/register", :company=>{:name=>"My Company LTD", :code=>"mcltd"}, :user=>{:last_name=>"Company", :first_name=>"My", :name=>"my", :password=>"12345678", :password_confirmation=>"12345678"}, :demo=>true
      assert_response :redirect
    end

  end



end
