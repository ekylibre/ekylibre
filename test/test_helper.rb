# -*- coding: utf-8 -*-
ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
if Rails.version.match(/^2\.3/)
  require 'test_help'
else
  require 'rails/test_help'
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def actions_of(cont)
    User.rights[cont].keys
  end

  def login(name, password)
    old_controller = @controller
    @controller = SessionsController.new
    post :create, :name=>name, :password=>password
    assert_redirected_to :controller=>:dashboards, :action=>:general, :company=>companies(:companies_001).code
    assert_not_nil(session[:user_id])
    @controller = old_controller
  end


end



class ActionController::TestCase
  if Rails.version.match(/^2\.3/)
    def response
      @response
    end
  end
  


  def self.get_actions(controller=nil)
    controller ||= self.controller_class.to_s[0..-11].underscore.to_sym
    for action in User.rights[controller].keys.sort{|a,b| a.to_s<=>b.to_s}
      should "get #{action}" do
        get action, :company=>@user.company.code
        assert_response :success, "The action #{action.inspect} does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"
        assert_select("html body div#body", :count=>1)
      end
    end
  end



  def self.test_restfully_all_actions(options={})
    controller ||= self.controller_class.to_s[0..-11].underscore.to_sym
    code  = "context 'A #{controller} controller' do\n"
    code += "  setup do\n"
    code += "    @user = users(:users_001)\n"
    code += "    login(@user.name, @user.comment)\n"
    code += "  end\n"
    except = options.delete(:except)||[]
    except = [except] unless except.is_a? Array
    # for ignored in except
    #   puts "Ignore: #{controller}##{ignored}"
    # end
    return unless User.rights[controller]
    for action in User.rights[controller].keys.sort{|a,b| a.to_s<=>b.to_s} # .delete_if{|x| except.include? x}
      if except.include? action
        puts "Ignore: #{controller}##{ignored}"
        next
      end

      code += "  should 'execute :#{action}' do\n"
      
      unless mode = options[action] and options[action].is_a? Symbol
        action_name = action.to_s
        mode = if action_name.match(/^(index|new)$/) # GET without ID
                 :index
               elsif action_name.match(/^(show|edit)$/) # GET with ID
                 :show
               elsif action_name.match(/^(create|load)$/) # POST without ID
                 :create
               elsif action_name.match(/^(update)$/) # PUT with ID
                 :update
               elsif action_name.match(/^(destroy)$/) # DELETE with ID
                 :destroy
               elsif action_name.match(/^(duplicate|up|down|lock|unlock|increment|decrement|propose|confirm|refuse|invoice|abort|correct|finish|propose_and_invoice|sort)$/) # POST with ID 
                 :touch
               end
      end

      model = controller.to_s.singularize
      if options[action].is_a? Hash
        # code += "    get :#{action}, :company=>@user.company.code\n"
        # code += "    assert_response :redirect\n"
        code += "    get :#{action}, :company=>@user.company.code, #{options[action].inspect[1..-2]}\n"
        code += '    assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
        # code += "    assert_select('html body div#body', 1, '#{action}'+response.inspect)\n"
      elsif mode == :index
        code += "    get :#{action}, :company=>@user.company.code\n"
        code += '    assert_response :success, "Flash: #{flash.inspect}"'+"\n"
      elsif mode == :show
        code += "    assert_raise ActionController::RoutingError, 'GET #{controller}/#{action}' do\n"
        code += "      get :#{action}, :company=>@user.company.code\n"
        code += "    end\n"
        code += "    get :#{action}, :company=>@user.company.code, :id=>1\n"
        code += '    assert_response :success, "Flash: #{flash.inspect}"'+"\n"
        code += "    assert_not_nil assigns(:#{model})\n"
      elsif mode == :create
        code += "    #{model} = #{controller}(:#{controller}_001)\n"
        code += "    assert_nothing_raised do\n"
        code += "      post :#{action}, :company=>@user.company.code, :#{model}=>#{model}.attributes\n"
        code += "    end\n"
      elsif mode == :update
        code += "    #{model} = #{controller}(:#{controller}_001)\n"
        code += "    assert_nothing_raised do\n"
        code += "      put :#{action}, :company=>@user.company.code, :id=>#{model}.id, :#{model}=>#{model}.attributes\n"
        code += "    end\n"
      elsif mode == :destroy
        code += "    assert_nothing_raised do\n"
        code += "      delete :#{action}, :company=>@user.company.code, :id=>2\n"
        code += "    end\n"
        code += "    assert_response :redirect\n"
      elsif mode == :touch
        code += "    assert_raise ActionController::RoutingError, 'POST #{controller}/#{action}' do\n"
        code += "      post :#{action}, :company=>@user.company.code\n"
        code += "    end\n"
        code += "    post :#{action}, :company=>@user.company.code, :id=>1\n"
        code += "    assert_response :redirect\n"
      elsif mode == :get_and_post # with ID
        code += "    assert_raise ActionController::RoutingError, 'GET #{controller}/#{action}' do\n"
        code += "      get :#{action}, :company=>@user.company.code\n"
        code += "    end\n"
        code += "    get :#{action}, :company=>@user.company.code, :id=>1\n"
        code += '    assert_response :success, "Flash: #{flash.inspect}"'+"\n"
      elsif mode == :index_xhr 
        code += "    get :#{action}, :company=>@user.company.code\n"
        code += "    assert_response :redirect\n"
        code += "    xhr :get, :#{action}, :company=>@user.company.code\n"
        code += '    assert_response :success, "Flash: #{flash.inspect}"'+"\n"
      elsif mode == :show_xhr
        code += "    get :#{action}, :company=>@user.company.code, :id=>1\n"
        code += "    assert_response :redirect\n"
        code += "    xhr :get, :#{action}, :company=>@user.company.code, :id=>1\n"
        code += "    assert_not_nil assigns(:#{model})\n"
      else
        code += "    get :#{action}, :company=>@user.company.code\n"
        code += '    assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
        code += "    assert_select('html body div#body', 1, '#{action}'+response.inspect)\n"
      end
      code += "  end\n"
    end
    code += "end"

    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    class_eval(code)
    
  end



  # def self.test_all_actions0(controller=nil)
  #   controller ||= self.controller_class.to_s[0..-11].underscore.to_sym
  #   code  = "def test_get_all_actions\n"
  #   code += "  user = users(:users_001)\n"
  #   code += "  login(user.name, user.comment)\n"
  #   for action in User.rights[controller].keys.sort{|a,b| a.to_s<=>b.to_s}.delete_if{|x| x.to_s.match(/_(delete|update)$/)}
  #     code += "  get #{action.inspect}, :company=>user.company.code\n"
  #     code += '  assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
  #     code += "  assert_select('html body div#body', :count=>1)\n"
  #   end
  #   code += "end"
  #   class_eval(code)
  # end


  # def self.test_all_actions(options={})
  #   controller ||= self.controller_class.to_s[0..-11].underscore.to_sym
  #   code  = "context 'A #{controller} controller' do\n"
  #   code += "  setup do\n"
  #   code += "    @user = users(:users_001)\n"
  #   code += "    login(@user.name, @user.comment)\n"
  #   code += "  end\n"
  #   except = options.delete(:except)||[]
  #   for action in User.rights[controller].keys.sort{|a,b| a.to_s<=>b.to_s}.delete_if{|x| except.include? x}
  #     code += "  should 'get #{action}' do\n"
  #     if options[action].is_a? Hash
  #       code += "    get #{action.inspect}, :company=>@user.company.code\n"
  #       code += "    assert_response :redirect\n"
  #       code += "    get #{action.inspect}, :company=>@user.company.code, #{options[action].inspect[1..-2]}\n"
  #       code += '    assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
  #       code += "    assert_select('html body div#body', 1, '#{action}'+response.inspect)\n"        
  #     elsif action.to_s.match(/_(delete|duplicate|up|down)$/) or options[action]==:delete
  #       code += "    get #{action.inspect}, :company=>@user.company.code\n"
  #       code += "    assert_not_nil flash[:notifications]\n"
  #       code += "    assert_response :redirect\n"
  #       code += "    get #{action.inspect}, :company=>@user.company.code, :id=>2\n"
  #       # code += "    assert_not_nil flash[:notifications]\n"
  #       code += "    assert_response :redirect\n"
  #     elsif action.to_s.match(/_update$/) or Ekylibre.references.keys.include?(action) or options[action]==:update
  #       code += "    get #{action.inspect}, :company=>@user.company.code\n"
  #       code += "    assert_response :redirect\n"
  #       code += "    get #{action.inspect}, :company=>@user.company.code, :id=>1\n"
  #       code += '    assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
  #       code += "    assert_select('html body div#body', 1, '#{action}'+response.inspect)\n"
  #     elsif action.to_s.match(/_load$/) or options[action]==:load
  #       code += "    get #{action.inspect}, :company=>@user.company.code\n"
  #       code += "    assert_response :redirect\n"
  #     elsif options[action]==:select
  #       code += "    get #{action.inspect}, :company=>@user.company.code\n"
  #       code += "    assert_response :redirect\n"
  #       code += "    get #{action.inspect}, :company=>@user.company.code, :id=>1\n"
  #       code += '    assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
  #       code += "    assert_select('html body div#body', 1, '#{action}'+response.inspect)\n"
  #     elsif action.to_s.match(/_(print|extract)$/)
  #     else # :list
  #       code += "    get #{action.inspect}, :company=>@user.company.code\n"
  #       code += '    assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
  #       code += "    assert_select('html body div#body', 1, '#{action}'+response.inspect)\n"
  #     end
  #     code += "  end\n"
  #   end
  #   code += "end"
  #   # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
  #   class_eval(code)
  # end
  
  # if options[action].is_a? Hash
  #       code += "    get :#{action}, :company=>@user.company.code\n"
  #       code += "    assert_response :redirect\n"
  #       code += "    get :#{action}, :company=>@user.company.code, #{options[action].inspect[1..-2]}\n"
  #       code += '    assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
  #       code += "    assert_select('html body div#body', 1, '#{action}'+response.inspect)\n"        
  #     elsif action.to_s.match(/index$/)
  #       code += "    get :#{action}, :company=>@user.company.code\n"
  #       code += "    assert_response :success\n"
  #     elsif action.to_s.match(/show$/)
  #       code += "    assert_raise ActionController::RoutingError, 'GET #{controller}/#{action}' do\n"
  #       code += "      get :#{action}, :company=>@user.company.code\n"
  #       code += "    end\n"
  #       code += "    get :#{action}, :company=>@user.company.code, :id=>1\n"
  #       code += "    assert_response :success\n"
  #     elsif action.to_s.match(/new$/)
  #       code += "    get :#{action}, :company=>@user.company.code\n"
  #       code += "    assert_response :success\n"
  #     elsif action.to_s.match(/create$/)
  #       #code += "    get :#{action}, :company=>@user.company.code\n"
  #       #code += "    assert_response :redirect\n"
  #     elsif action.to_s.match(/edit$/)
  #       code += "    assert_raise ActionController::RoutingError do\n"
  #       code += "      get :#{action}, :company=>@user.company.code\n"
  #       code += "    end\n"
  #       code += "    get :#{action}, :company=>@user.company.code, :id=>1\n"
  #       code += '    assert_response :success, "The action :#{action} does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
  #       code += "    assert_select('html body div#body', 1, '#{action}'+response.inspect)\n"
  #     elsif action.to_s.match(/update$/)
  #       #code += "    get :#{action}, :company=>@user.company.code\n"
  #       #code += "    assert_response :redirect\n"
  #       #code += "    get :#{action}, :company=>@user.company.code, :id=>1\n"
  #       #code += "    assert_response :redirect\n"
  #       #code += "    assert_select('html body div#body', 1, '#{action}'+response.inspect)\n"
  #     elsif action.to_s.match(/^destroy$/) or options[action]==:destroy
  #       code += "    delete :#{action}, :company=>@user.company.code, :id=>2\n"
  #       code += "    assert_response :redirect\n"
  #     elsif action.to_s.match(/^(duplicate|up|down|lock|unlock|increment|decrement|propose|refuse|invoice|abort|correct|propose_and_invoice)$/)
  #       code += "    assert_raise ActionController::RoutingError, 'POST #{controller}/#{action}' do\n"
  #       code += "      post :#{action}, :company=>@user.company.code\n"
  #       code += "    end\n"
  #       code += "    post :#{action}, :company=>@user.company.code, :id=>1\n"
  #       # code += "    assert_not_nil flash[:notifications]\n"
  #       code += "    assert_response :redirect\n"
  #     elsif action.to_s.match(/load$/) or options[action]==:load
  #       # code += "    get :#{action}, :company=>@user.company.code\n"
  #       # code += "    assert_response :redirect\n"
  #     elsif options[action]==:select
  #       code += "    get :#{action}, :company=>@user.company.code\n"
  #       code += "    assert_response :redirect\n"
  #       code += "    get :#{action}, :company=>@user.company.code, :id=>1\n"
  #       code += '    assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
  #       code += "    assert_select('html body div#body', 1, '#{action}'+response.inspect)\n"
  #     elsif action.to_s.match(/_(print|extract)$/)
  #     else # :list
  #       code += "    get :#{action}, :company=>@user.company.code\n"
  #       code += '    assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
  #       code += "    assert_select('html body div#body', 1, '#{action}'+response.inspect)\n"
  #     end
  #     code += "  end\n"
  #   end
  #   code += "end"
  #   # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
  #   class_eval(code)

  # end

end

