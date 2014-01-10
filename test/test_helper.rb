require 'coveralls'
Coveralls.wear!('rails')
ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
# require 'sauce_helper'
require 'capybara/rails'
# require 'capybara/poltergeist'

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionController::TestCase
  include Devise::TestHelpers

  class << self

    def test_restfully_all_actions(options={})
      controller_name = self.controller_class.controller_name
      controller_path = self.controller_class.controller_path
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
        attributes = model.content_columns.map(&:name).map(&:to_sym).delete_if{|c|
          [:depth, :lft, :rgt].include?(c)
        }
        attributes = ("{" + attributes.collect do |a|
                        if file_columns[a.to_sym]
                          "#{a}: fixture_file_upload('files/sample_image.png')"
                        else
                          "#{a}: #{record}.#{a}"
                        end
                      end.join(", ")+ "}").c
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
      code << "\n"

      actions = self.controller_class.action_methods.to_a.map(&:to_sym)
      actions &= [options.delete(:only)].flatten if options[:only]
      actions -= [options.delete(:except)].flatten if options[:except]

      ignored = self.controller_class.action_methods.to_a.map(&:to_sym) - actions
      puts "Ignore in #{controller_path}: " + ignored.join(', ') if ignored.any?

      for action in actions
        action_label = "#{controller_path}##{action}"

        params, mode = {}, options[action]
        if mode.is_a?(Hash)
          if mode[:params] or mode[:mode]
            params.update(mode[:params])
            mode = mode[:mode]
          else
            params.update(mode)
            mode = nil
          end
        end
        mode ||= choose_mode(action_label)

        code << "  should '#{action} (#{mode})' do\n"

        params.deep_symbolize_keys!
        sanitized_params = Proc.new { |p = {}|
          p.deep_symbolize_keys.deep_merge(params).inspect.gsub('RECORD', record)
        }
        if mode == :index
          code << "    get :#{action}, #{sanitized_params[]}\n"
          code << "    assert_response :success\n"
          code << "    assert_select('html body #main #content', 1, 'Cannot find #main #content element')\n"
        elsif mode == :new_product
          code << "    get :#{action}, #{sanitized_params[]}\n"
          code << "    if ProductNatureVariant.of_variety('#{model_name.underscore}').any?\n"
          code << "      assert_response :success\n"
          code << "    else\n"
          code << "      assert_response :redirect\n"
          code << "    end\n"
        elsif mode == :show
          code << "    assert_nothing_raised do\n"
          code << "      get :#{action}, #{sanitized_params[id: 'NaID']}\n"
          code << "    end\n"
          if model
            code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
            code << "    assert_equal 1, #{model_name}.where(id: #{record}.id).count\n"
            code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
            code << "    get :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
            code << "    assert_response :success\n"
            code << "    assert_not_nil assigns(:#{record})\n"
          end
        elsif mode == :picture
          code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          code << "    assert_equal 1, #{model_name}.where(id: #{record}.id).count\n"
          code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          code << "    get :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          code << "    if #{record}.picture.file?\n"
          code << "      assert_response :success\n"
          code << "      assert_not_nil assigns(:#{record})\n"
          code << "    end\n"
        elsif mode == :list_things
          code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          code << "    assert_equal 1, #{model_name}.where(id: #{record}.id).count\n"
          code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          code << "    get :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          code << "    assert_response :success\n"
          for format in [:csv, :xcsv, :ods]
            code << "    get :#{action}, #{sanitized_params[id: 'RECORD.id'.c, format: format]}\n"
            code << "    assert_response :success, 'Action #{action} does not export in format #{format}'\n"
          end
        elsif mode == :create
          code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          code << "    post :#{action}, #{sanitized_params[record => attributes]}\n"
        elsif mode == :update
          code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          code << "    patch :#{action}, #{sanitized_params[id: 'RECORD.id'.c, record => attributes]}\n"
        elsif mode == :destroy
          code << "    #{record} = #{fixture_table}(:#{fixture_name}_002)\n"
          code << "    assert_nothing_raised do\n"
          code << "      delete :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          code << "    end\n"
          code << "    assert_response :redirect\n"
        elsif mode == :list
          code << "    get :#{action}, #{sanitized_params[]}\n"
          code << "    assert_response :success, \"The action #{action.inspect} does not seem to support GET method \#{redirect_to_url} / \#{flash.inspect}\"\n"
          for format in [:csv, :xcsv, :ods]
            code << "    get :#{action}, #{sanitized_params[format: format]}\n"
            code << "    assert_response :success, 'Action #{action} does not export in format #{format}'\n"
          end
        elsif mode == :touch
          code << "    post :#{action}, #{sanitized_params[id: 'NaID']}\n"
          code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          code << "    post :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          code << "    assert_response :redirect\n"
        elsif mode == :soft_touch
          code << "    post :#{action}, #{sanitized_params[]}\n"
          code << "    assert_response :success\n"
        elsif mode == :redirected_get # with ID
          code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          code << "    get :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          code << "    assert_response :redirect\n"
        elsif mode == :get_and_post # with ID
          code << "    get :#{action}, #{sanitized_params[id: 'NaID']}\n"
          code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          code << "    get :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          code << "    assert_response :success\n"
        elsif mode == :index_xhr
          code << "    get :#{action}, #{sanitized_params[]}\n"
          code << "    assert_response :redirect\n"
          code << "    xhr :get, :#{action}, #{sanitized_params[]}\n"
          code << "    assert_response :success\n"
        elsif mode == :show_xhr
          code << "    #{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          code << "    assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          code << "    get :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          code << "    assert_response :redirect\n"
          code << "    xhr :get, :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          code << "    assert_not_nil assigns(:#{record})\n"
        elsif mode == :unroll
          code << "    xhr :get, :#{action}, #{sanitized_params[]}\n"
          code << "    xhr :get, :#{action}, #{sanitized_params[format: :json]}\n"
          code << "    xhr :get, :#{action}, #{sanitized_params[format: :xml]}\n"
          # TODO test all scopes
        elsif mode == :get
          code << "    get :#{action}, #{sanitized_params[]}\n"
          code << "    assert_response :success\n"
        else
          code << "    raise StandardError, 'What is this mode? #{mode.inspect}'\n"
        end
        code << "  end\n\n"
      end
      code << "end\n"

      file = Rails.root.join("tmp", "code", "test", "#{controller_path}.rb")
      FileUtils.mkdir_p(file.dirname)
      File.open(file, "wb") do |f|
        f.write(code)
      end

      class_eval(code, "(test) #{controller_path}") # :#{__LINE__}
    end

    MODES = {
      /\Abackend\/cells\/.*\#show\z/ => :get,
      # /\Abackend\/cells\/.*\#list\z/ => :index_xhr,
      /\#(index|new)\z/   => :index,
      /\#(show|edit)\z/   => :show,
      /\#picture\z/       => :picture,
      /\#list\_\w+\z/     => :list_things,
      /\#list\z/          => :list,
      /\#(create|load)\z/ => :create,
      /\#update\z/        => :update,
      /\#destroy\z/       => :destroy,
      /\#(decrement|duplicate|down|lock|toggle|unlock|up|increment|propose|confirm|refuse|invoice|abort|correct|finish|propose_and_invoice|sort|run)\z/ => :touch,
      /\#unroll\z/        => :unroll
    }

    def choose_mode(action)
      array = action.to_s.split('#')
      action_name = array.last.to_sym
      if action_name == :new
        model = array.first.split(/\//).last.classify.constantize rescue nil
        return :new_product if model and model <= Product
      end
      for exp, mode in MODES
        return mode if action =~ exp
      end
      return :get
    end


  end
end


# Capybara.register_driver :selenium do |app|
#   custom_profile = Selenium::WebDriver::Firefox::Profile.new
#   # Turn off the super annoying popup!
#   custom_profile["network.http.prompt-temp-redirect"] = false
#   Capybara::Selenium::Driver.new(app, :browser => :firefox, :profile => custom_profile)
# end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, debug: true, inspector: true) # ENV["CI"].blank?
end

# To run all tests with ?
Capybara.default_driver    = :webkit # :sauce # :selenium
Capybara.current_driver    = :webkit # :sauce # :selenium
Capybara.javascript_driver = :webkit # :sauce # :selenium

# Capybara.default_wait_time = 5
# Capybara.server_port = 3333

# class CapybaraIntegrationTest < Sauce::RailsTestCase
class CapybaraIntegrationTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  # # include Capybara::Screenshot
  include Warden::Test::Helpers
  Warden.test_mode!

  def shoot_screen(name = nil)
    name ||= current_url.split(/\:\d+\//).last
    sleep(1)
    file = Rails.root.join("tmp", "screenshots", name + ".png")
    FileUtils.mkdir_p(file.dirname) unless file.dirname.exist?
    save_page file.to_s.gsub(/\.png\z/, '.html')
    save_screenshot file # , full: true
  end

  # Add a method to test unroll in form
  # FIXME : add an AJAX helpers to capybara for testing unroll field
  # http://stackoverflow.com/questions/13187753/rails3-jquery-autocomplete-how-to-test-with-rspec-and-capybara/13213185#13213185
  # http://jackhq.tumblr.com/post/3728330919/testing-jquery-autocomplete-using-capybara
  def fill_unroll(field, options = {})
    fill_in(field, with: options[:with])
    sleep(3)
    shoot_screen "#{options[:name]}/unroll-before"
    selector = "input##{field} + .items-menu .items-list .item[data-item-label=\"#{options[:select]}\"]"
    # page.should have_xpath(selector)
    page.execute_script "$('#{selector}').trigger('mouseenter').click();"
    shoot_screen "#{options[:name]}/unroll-after"
  end

end
