ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

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
    @controller = AuthenticationController.new
    post :login, :name=>name, :password=>password
    assert_redirected_to :controller=>:company, :action=>:index, :company=>companies(:companies_001).code
    assert_not_nil(session[:user_id])
    @controller = old_controller
  end


end



class ActionController::TestCase

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



  def self.test_all_actions0(controller=nil)
    controller ||= self.controller_class.to_s[0..-11].underscore.to_sym
    code  = "def test_get_all_actions\n"
    code += "  user = users(:users_001)\n"
    code += "  login(user.name, user.comment)\n"
    for action in User.rights[controller].keys.sort{|a,b| a.to_s<=>b.to_s}.delete_if{|x| x.to_s.match(/_(delete|update)$/)}
      code += "  get #{action.inspect}, :company=>user.company.code\n"
      code += '  assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
      code += "  assert_select('html body div#body', :count=>1)\n"
    end
    code += "end"
    class_eval(code)
  end


  def self.test_all_actions(options={})
    controller ||= self.controller_class.to_s[0..-11].underscore.to_sym
    code  = "context 'A #{controller} controller' do\n"
    code += "  setup do\n"
    code += "    @user = users(:users_001)\n"
    code += "    login(@user.name, @user.comment)\n"
    code += "  end\n"
    except = options.delete(:except)||[]
    for action in User.rights[controller].keys.sort{|a,b| a.to_s<=>b.to_s}.delete_if{|x| except.include? x}
      code += "  should 'get #{action}' do\n"
      if options[action].is_a? Hash
        code += "    get #{action.inspect}, :company=>@user.company.code\n"
        code += "    assert_response :redirect\n"
        code += "    get #{action.inspect}, :company=>@user.company.code, #{options[action].inspect[1..-2]}\n"
        code += '    assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
        code += "    assert_select('html body div#body', :count=>1)\n"        
      elsif action.to_s.match(/_(delete|duplicate)$/) or options[action]==:delete
        code += "    get #{action.inspect}, :company=>@user.company.code\n"
        code += "    assert_not_nil flash[:notifications]\n"
        code += "    assert_response :redirect\n"
        code += "    get #{action.inspect}, :company=>@user.company.code, :id=>2\n"
        # code += "    assert_not_nil flash[:notifications]\n"
        code += "    assert_response :redirect\n"
      elsif action.to_s.match(/_update$/) or Ekylibre.references.keys.include?(action) or options[action]==:update
        code += "    get #{action.inspect}, :company=>@user.company.code\n"
        code += "    assert_response :redirect\n"
        code += "    get #{action.inspect}, :company=>@user.company.code, :id=>1\n"
        code += '    assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
        code += "    assert_select('html body div#body', :count=>1)\n"
      elsif action.to_s.match(/_load$/) or options[action]==:load
        code += "    get #{action.inspect}, :company=>@user.company.code\n"
        code += "    assert_response :redirect\n"
      elsif options[action]==:select
        code += "    get #{action.inspect}, :company=>@user.company.code\n"
        code += "    assert_response :redirect\n"
        code += "    get #{action.inspect}, :company=>@user.company.code, :id=>1\n"
        code += '    assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
        code += "    assert_select('html body div#body', :count=>1)\n"
      elsif action.to_s.match(/_(print|extract)$/)
      else # :list
        code += "    get #{action.inspect}, :company=>@user.company.code\n"
        code += '    assert_response :success, "The action '+action.inspect+' does not seem to support GET method #{redirect_to_url} / #{flash.inspect}"'+"\n"
        code += "    assert_select('html body div#body', :count=>1)\n"
      end
      code += "  end\n"
    end
    code += "end"
    class_eval(code)
  end

end

