require 'test_helper'

class AuthenticationControllerTest < ActionController::TestCase
  fixtures :companies
  
  context "Authentication" do
    should "redirect index to login" do
      get :index
      assert_redirected_to(:controller=>:authentication, :action=>:login)
    end
    
    should "accept valid user" do
      get :login
      assert_response :success
      post :login, :name=>'mikmak', :password=>'secret'
      assert_redirected_to :controller=>:company, :action=>:index, :company=>companies(:companies_001).code
    end
    
    should "refuse invalid user" do
      get :login
      assert_response :success
      post :login, :name=>'mikmak', :password=>'wrong'
      assert_template "login"
      post :login, :name=>'wrong', :password=>'secret'
      assert_template "login"
      post :login, :name=>'Mikmak', :password=>'secret'
      assert_template "login"
      post :login, :name=>'mikmak', :password=>'Secret'
      assert_template "login"
    end
    
  end


end
