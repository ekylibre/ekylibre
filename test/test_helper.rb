# -*- coding: utf-8 -*-
require 'coveralls'
Coveralls.wear!('rails')

ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
# require 'rspec/rails'
# require 'rspec/autorun'
require 'capybara/rails'
# require 'capybara/rspec'
# require 'capybara-screenshot/rspec'


# Removes use of shoulda gem until bug is not fixed for Rails >= 1.9.3
# Use specific file lib/shoulda/context/context.rb
# TODO: Re-add shoulda-context in Gemfile ASAP
# require File.join(File.dirname(__FILE__), 'shoulda-context')
# class ActiveSupport::TestCase
#   include Shoulda::Context::InstanceMethods
#   extend Shoulda::Context::ClassMethods
# end


# Choix du driver par défaut : selenium pour le Javascript
#
Capybara.default_driver = :selenium
Capybara.default_wait_time = 5
#Capybara.default_driver = :webkit

class CapybaraIntegrationTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Screenshot
  include Warden::Test::Helpers
  Warden.test_mode!

  def shoot_screen(name)
    file = Rails.root.join("tmp", "screenshots", name + ".png")
    FileUtils.mkdir_p(file.dirname) unless file.dirname.exist?
    save_screenshot file
  end

  #add a method to test unroll in form
  #FIXME : add an AJAX helpers to capybara for testing unroll field
    # http://stackoverflow.com/questions/13187753/rails3-jquery-autocomplete-how-to-test-with-rspec-and-capybara/13213185#13213185
    # http://jackhq.tumblr.com/post/3728330919/testing-jquery-autocomplete-using-capybara
  def fill_unroll(field, options = {})
    fill_in field, :with => options[:with]
    sleep(1)
    #page.execute_script %Q{ $('##{field}').trigger("focus") }
    #page.execute_script %Q{ $('##{field}').trigger("keydown") }
    selector = "input##{field} + .items-menu .items-list .item[data-item-label=\"#{options[:select]}\"]"
    #page.should have_xpath(selector)
    page.execute_script "$('#{selector}').trigger('mouseenter').click();"
  end

end



class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def actions_of(cont)
    User.rights[cont].keys
  end

  # def login(name, password)
  #   # print "L"
  #   old_controller = @controller
  #   @controller = SessionsController.new
  #   post :create, :name => name, :password => password
  #   assert_response :redirect
  #   assert_redirected_to root_url, "If login succeed, a redirection must be done to #{root_url}"
  #   assert_not_nil(session[:user_id])
  #   @controller = old_controller
  # end

  def fast_login(entity)
    # print "V"
    @controller.send(:init_session, entity)
  end


end



class ActionController::TestCase
  include Devise::TestHelpers

  def self.test_restfully_all_actions(options={})
    controller_name = self.controller_class.controller_name
    table_name = controller_name
    model_name = table_name.classify
    model = model_name.constantize rescue nil
    record = model_name.underscore
    attributes = nil
    file_columns = {}
    if model and model < ActiveRecord::Base
      table_name = model.table_name
      if model.respond_to?(:attachment_definitions)
        unless model.attachment_definitions.nil?
          file_columns = model.attachment_definitions
        end
      end
      attributes = model.content_columns.map(&:name).map(&:to_sym).delete_if{|c| [:depth, :lft, :rgt].include?(c) }
      attributes = "{" + attributes.collect do |a|
        if file_columns[a.to_sym]
          "#{a}: fixture_file_upload('files/sample_image.png')"
        else
          "#{a}: #{record}.#{a}"
        end
      end.join(", ")+ "}"
    end

    fixture_name = record.pluralize
    fixture_table = table_name

    code  = ""
    code << "context 'A #{controller_name} controller' do\n"
    code << "\n"
    code << "  setup do\n"
    code << "    I18n.locale = I18n.default_locale\n"
    code << "    assert_not_nil I18n.locale\n"
    code << "    assert_equal I18n.locale, I18n.locale, I18n.locale.inspect\n"
    code << "    @user = users(:users_001)\n"
    code << "    sign_in(@user)\n"
    code << "    CustomField.all.each(&:save)\n"
    code << "  end\n"

    except = [options.delete(:except)].flatten.compact.map(&:to_sym)
    for action in self.controller_class.action_methods.to_a
      action = action.to_sym
      if except.include? action
        puts "Ignore: #{controller_name}##{action}"
        next
      end

      code << "\n"
      code << "  should \"#{action}\" do\n"

      unless mode = options[action] and options[action].is_a? Symbol
        action_name = action.to_s
        mode = if action_name.match(/\A(index|new)\z/) # GET without ID
                 :index
               elsif action_name.match(/\A(show|edit|picture)\z/) # GET with ID
                 :show
               elsif action_name.match(/\A(show|edit)\z/) # GET with ID
                 :picture
               elsif action_name.match(/\A(list\_\w+)\z/) # GET with ID
                 :list_things
               elsif action_name.match(/\A(create|load)\z/) # POST without ID
                 :create
               elsif action_name.match(/\A(update)\z/) # PATCH with ID
                 :update
               elsif action_name.match(/\A(destroy)\z/) # DELETE with ID
                 :destroy
               elsif action_name.match(/\Alist\z/) # GET list
                 :list
               elsif action_name.match(/\Aunroll\z/) # GET list
                 :unroll
               elsif action_name.match(/\A(duplicate|up|down|lock|unlock|increment|decrement|propose|confirm|refuse|invoice|abort|correct|finish|propose_and_invoice|sort)\z/) # POST with ID
                 :touch
               end
      end

      if options[action].is_a? Hash
        code << "    get :#{action}, #{options[action].inspect[1..-2]}\n"
        code << "    assert_response :success, \"The action #{action.inspect} does not seem to support GET method \#{redirect_to_url} / \#{flash.inspect}\"\n"
      elsif mode == :index
        code << "    get :#{action}\n"
        code << '    assert_response :success, "Flash: #{flash.inspect}"'+"\n"
      elsif mode == :show
        code << "    assert_nothing_raised do\n"
        code << "      get :#{action}, id: 'NaID'\n"
        code << "    end\n"
        if model
          code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          code << "    assert_equal 1, #{model_name}.where(id: #{record}.id).count\n"
          code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          code << "    get :#{action}, id: #{record}.id\n"
          code << "    assert_response :success, \"Flash: \#{flash.inspect}\"\n"
          code << "    assert_not_nil assigns(:#{record})\n"
        end
      elsif mode == :picture
        code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
        code << "    assert_equal 1, #{model_name}.where(id: #{record}.id).count\n"
        code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
        code << "    get :#{action}, id: #{record}.id\n"
        code << "    if #{record}.picture.file?\n"
        code << "      assert_response :success, \"Flash: \#{flash.inspect}\"\n"
        code << "      assert_not_nil assigns(:#{record})\n"
        code << "    end\n"
      elsif mode == :list_things
        code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
        code << "    assert_equal 1, #{model_name}.where(id: #{record}.id).count\n"
        code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
        code << "    get :#{action}, id: #{record}.id\n"
        code << "    assert_response :success, \"Flash: \#{flash.inspect}\"\n"
      elsif mode == :create
        code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
        code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
        code << "    post :#{action}, #{record}: #{attributes}\n"
      elsif mode == :update
        code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
        code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
        code << "    patch :#{action}, id: #{record}.id, #{record}: #{attributes}\n"
      elsif mode == :destroy
        code << "    #{record} = #{fixture_table}(:#{fixture_name}_002)\n"
        code << "    assert_nothing_raised do\n"
        code << "      delete :#{action}, id: #{record}.id\n"
        code << "    end\n"
        code << "    assert_response :redirect\n"
      elsif mode == :list
        code << "    get :#{action}\n"
        code << "    assert_response :success, \"The action #{action.inspect} does not seem to support GET method \#{redirect_to_url} / \#{flash.inspect}\"\n"
        for format in [:csv, :xcsv, :ods]
          code << "    get :#{action}, :format => :#{format}\n"
          code << "    assert_response :success, 'Action #{action} does not export in format #{format}'\n"
        end
      elsif mode == :touch
        code << "    post :#{action}, id: 'NaID'\n"
        code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
        code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
        code << "    post :#{action}, id: #{record}.id\n"
        code << "    assert_response :redirect\n"
      elsif mode == :get_and_post # with ID
        code << "    get :#{action}, id: 'NaID'\n"
        code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
        code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
        code << "    get :#{action}, id: #{record}.id\n"
        code << '    assert_response :success, "Flash: #{flash.inspect}"'+"\n"
      elsif mode == :index_xhr
        code << "    get :#{action}\n"
        code << "    assert_response :redirect\n"
        code << "    xhr :get, :#{action}\n"
        code << '    assert_response :success, "Flash: #{flash.inspect}"'+"\n"
      elsif mode == :show_xhr
        code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
        code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
        code << "    get :#{action}, id: #{record}.id\n"
        code << "    assert_response :redirect\n"
        code << "    xhr :get, :#{action}, id: #{record}.id\n"
        code << "    assert_not_nil assigns(:#{record})\n"
      elsif mode == :unroll
        code << "    xhr :get, :#{action}\n"
        code << "    xhr :get, :#{action}, format: :json\n"
        code << "    xhr :get, :#{action}, format: :xml\n"
        # TODO test all scopes
      else
        code << "    get :#{action}\n"
        code << "    assert_response :success, \"The action #{action.inspect} does not seem to support GET method \#{redirect_to_url} / \#{flash.inspect}\"\n"
        code << "    assert_select('html body div#wrap', 1, 'Cannot get main element in view #{action}')\n" # +response.inspect
      end
      code << "  end\n"
    end
    code << "end\n"

    file = Rails.root.join("tmp", "code", "test", "#{self.controller_class.controller_path}.rb")
    FileUtils.mkdir_p(file.dirname)
    File.open(file, "wb") do |f|
      f.write(code)
    end
    class_eval(code, "#{__FILE__}:#{__LINE__}")
  end
end

