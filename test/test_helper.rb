ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

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
      if action.to_s.match(/_delete$/) or options[action]==:delete
        code += "    get #{action.inspect}, :company=>@user.company.code\n"
        code += "    assert_response :redirect\n"
        code += "    get #{action.inspect}, :company=>@user.company.code, :id=>2\n"
        # code += "    assert_not_nil flash[:notifications]\n"
        code += "    assert_response :redirect\n"
      elsif action.to_s.match(/_update$/) or EKYLIBRE_REFERENCES.keys.include?(action) or options[action]==:update
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

