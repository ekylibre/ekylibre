require 'test_helper'

Struct.new("MockedUser", :name, :comment)

class UserTest < ActionController::IntegrationTest
  fixtures :all

  context "A valid user" do
    setup do
      @user = Struct::MockedUser.new('gendo', 'secret') # users(:users_001)
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
        assert_redirected_to :controller=>:dashboards, :action=>:general
      end

      should "change its password" do 
        get "me/change_password"
        assert_response :success
        post "me/change_password", :user=>{:old_password=>@user.comment, :password=>"abcdefgh", :password_confirmation=>"abcdefgh"}
        assert_response :redirect
        delete "session"
        assert_response :redirect
        post "session", :name=>@user.name, :password=>"abcdefgh"
        assert_redirected_to :controller=>:dashboards, :action=>:general
        get "me/change_password"
        assert_response :success
        post "me/change_password", :user=>{:old_password=>"abcdefgh", :password=>@user.comment, :password_confirmation=>@user.comment}
        assert_response :redirect
      end

    end

  end


  context "An unknown user" do
    
    should "register a new company" do
      get "company/register"
      assert_response :success
      post "company/register", :my_company=>{:name=>"My Company LTD", :code=>"mcltd1", :currency=>"JPY"}, :user=>{:last_name=>"Company", :first_name=>"My", :name=>"my1", :password=>"12345678", :password_confirmation=>"12345678"}
      assert_redirected_to :controller=>:dashboards, :action=>:welcome
    end

    should "register a new company with english data" do
      get "company/register"
      assert_response :success
      post "company/register", :my_company=>{:name=>"My Company LTD", :code=>"mcltd2", :currency=>"USD"}, :user=>{:last_name=>"Company", :first_name=>"My", :name=>"my2", :password=>"12345678", :password_confirmation=>"12345678"}, :demo=>"eng"
      assert_redirected_to :controller=>:dashboards, :action=>:welcome
    end

    should "register a new company with french data" do
      get "company/register"
      assert_response :success
      post "company/register", :my_company=>{:name=>"My Company LTD", :code=>"mcltd3", :currency=>"EUR"}, :user=>{:last_name=>"Company", :first_name=>"My", :name=>"my3", :password=>"12345678", :password_confirmation=>"12345678"}, :demo=>"fra"
      assert_redirected_to :controller=>:dashboards, :action=>:welcome
    end

  end



end
