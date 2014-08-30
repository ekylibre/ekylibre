require 'coveralls'
Coveralls.wear!('rails')
ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'capybara/rails'

# Permits to test locales
if ENV['LOCALE']
  I18n.locale = ENV['LOCALE']
end


class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class HashCollector

  def initialize
    @hash = {}
  end

  def to_hash
    return @hash
  end

  def method_missing(method_name, *args, &block)
    @hash[method_name.to_sym] = args.first
  end

end


class ActionController::TestCase
  include Devise::TestHelpers

  class << self

    # Returns ID of the given label
    def identify(label)
      ActiveRecord::FixtureSet.identify(label)
    end

    def test_restfully_all_actions(options = {}, &block)
      controller_name = self.controller_class.controller_name
      controller_path = self.controller_class.controller_path
      table_name = controller_name
      model_name = table_name.classify
      model = model_name.constantize rescue nil
      record = model_name.underscore
      other_record = "other_#{record}"
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

      if block_given?
        collector = HashCollector.new
        yield collector
        options.update(collector.to_hash)
      end

      code  = ""
      # code << "context 'A #{controller_name} controller' do\n"
      # code << "\n"
      # code << "  setup do\n"
      # code << "    I18n.locale = I18n.default_locale\n"
      # code << "    assert_not_nil I18n.locale\n"
      # code << "    assert_equal I18n.locale, I18n.locale, I18n.locale.inspect\n"
      # code << "    @user = users(:users_001)\n"
      # code << "    sign_in(@user)\n"
      # code << "    for cf in [:custom_fields_001, :custom_fields_002]\n"
      # code << "      record = custom_fields(cf)\n"
      # code << "      assert record.save, record.errors.inspect\n"
      # code << "    end\n"
      # code << "  end\n"
      # code << "\n"

      code << "setup do\n"
      # Check locale
      code << "  I18n.locale = ENV['LOCALE'] || I18n.default_locale\n"
      code << "  assert_not_nil I18n.locale\n"
      code << "  assert_equal I18n.locale, I18n.locale, I18n.locale.inspect\n"
      # Check document templates
      code << "  DocumentTemplate.load_defaults(locale: I18n.locale)\n"
      # Check custom fields
      code << "  for cf in [:custom_fields_001, :custom_fields_002]\n"
      code << "    record = custom_fields(cf)\n"
      code << "    assert record.save, record.errors.inspect\n"
      code << "  end\n"
      # Connect user
      code << "  @user = users(:users_001)\n"
      code << "  sign_in(@user)\n"
      # Setup finished!
      code << "end\n"
      code << "\n"

      code << "def teardown\n"
      code << "  sign_out(@user)\n"
      code << "end\n"
      code << "\n"

      actions = self.controller_class.action_methods.to_a.map(&:to_sym)
      actions &= [options.delete(:only)].flatten if options[:only]
      actions -= [options.delete(:except)].flatten if options[:except]

      ignored = self.controller_class.action_methods.to_a.map(&:to_sym) - actions
      puts "Ignore in #{controller_path}: " + ignored.join(', ') if ignored.any?


      show_notification = '(flash[:notification].is_a?(Hash) ? "Notifications are: " + flash[:notification].collect{|k,v| "#{k}: " + v.to_sentence(locale: :eng)}.to_sentence(locale: :eng) : "No given notifications") + "."'

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

        test_code = ""
        params.deep_symbolize_keys!
        sanitized_params = Proc.new { |p = {}|
          p.deep_symbolize_keys.deep_merge(params).inspect.gsub('OTHER_RECORD', other_record).gsub('RECORD', record)
        }
        if mode == :index
          test_code << "get :#{action}, #{sanitized_params[]}\n"
          test_code << "assert_response :success, #{show_notification}\n"
          if params[:format] == :json
            # TODO: JSON parsing test
          else
            test_code << "assert_select('html body #main #content', 1, 'Cannot find #main #content element')\n"
          end
        elsif mode == :new_product
          test_code << "get :#{action}, #{sanitized_params[]}\n"
          test_code << "if ProductNatureVariant.of_variety('#{model_name.underscore}').any?\n"
          test_code << "  assert_response :success, #{show_notification}\n"
          test_code << "else\n"
          test_code << "  assert_response :redirect, #{show_notification}\n"
          test_code << "end\n"
        elsif mode == :show
          test_code << "assert_nothing_raised do\n"
          test_code << "  get :#{action}, #{sanitized_params[id: 'NaID']}\n"
          test_code << "end\n"
          if model
            test_code << "#{record} = #{fixture_table}(:#{fixture_name}_001)\n"
            test_code << "assert_equal 1, #{model_name}.where(id: #{record}.id).count\n"
            test_code << "assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
            test_code << "get :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
            test_code << "assert_response :success, #{show_notification}\n"
            test_code << "assert_not_nil assigns(:#{record})\n"
          end
        elsif mode == :picture
          test_code << "#{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          test_code << "assert_equal 1, #{model_name}.where(id: #{record}.id).count\n"
          test_code << "assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          test_code << "get :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          test_code << "if #{record}.picture.file?\n"
          test_code << "  assert_response :success, #{show_notification}\n"
          test_code << "  assert_not_nil assigns(:#{record})\n"
          test_code << "end\n"
        elsif mode == :list_things
          test_code << "#{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          test_code << "assert_equal 1, #{model_name}.where(id: #{record}.id).count\n"
          test_code << "assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          test_code << "get :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          test_code << "assert_response :success, #{show_notification}\n"
          for format in [:csv, :ods] # :xcsv,
            test_code << "get :#{action}, #{sanitized_params[id: 'RECORD.id'.c, format: format]}\n"
            test_code << "assert_response :success, 'Action #{action} does not export in format #{format}'\n"
          end
        elsif mode == :create
          test_code << "#{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          test_code << "assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          test_code << "post :#{action}, #{sanitized_params[record => attributes]}\n"
        elsif mode == :update
          test_code << "#{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          test_code << "assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          test_code << "patch :#{action}, #{sanitized_params[id: 'RECORD.id'.c, record => attributes]}\n"
        elsif mode == :destroy
          test_code << "#{record} = #{fixture_table}(:#{fixture_name}_002)\n"
          test_code << "assert_nothing_raised do\n"
          test_code << "  delete :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          test_code << "end\n"
          test_code << "assert_response :redirect, #{show_notification}\n"
        elsif mode == :list
          test_code << "get :#{action}, #{sanitized_params[]}\n"
          test_code << "assert_response :success, \"The action #{action.inspect} does not seem to support GET method \#{redirect_to_url} / \#{flash.inspect}\"\n"
          for format in [:csv, :ods] # , :xcsv
            test_code << "get :#{action}, #{sanitized_params[format: format]}\n"
            test_code << "assert_response :success, 'Action #{action} does not export in format #{format}'\n"
          end
        elsif mode == :touch
          test_code << "post :#{action}, #{sanitized_params[id: 'NaID']}\n"
          test_code << "#{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          test_code << "assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          test_code << "post :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          test_code << "assert_response :redirect, #{show_notification}\n"
        elsif mode == :soft_touch
          test_code << "post :#{action}, #{sanitized_params[]}\n"
          test_code << "assert_response :success, #{show_notification}\n"
        elsif mode == :multi_touch
          test_code << "post :#{action}, #{sanitized_params[id: 'NaID']}\n"
          test_code << "#{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          test_code << "assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          test_code << "post :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          test_code << "assert_response :redirect, #{show_notification}\n"
          # Multi IDS
          test_code << "#{other_record} = #{fixture_table}(:#{fixture_name}_003)\n"
          test_code << "assert #{other_record}.valid?, '#{fixture_name}_003 must be valid:' + #{other_record}.errors.inspect\n"
          test_code << "post :#{action}, " + sanitized_params[id: '[RECORD.id, OTHER_RECORD.id].join(", ")'.c] + "\n"
          test_code << "assert_response :redirect, #{show_notification}\n"
        elsif mode == :redirected_get # with ID
          test_code << "#{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          test_code << "assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          test_code << "get :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          test_code << "assert_response :redirect, #{show_notification}\n"
        elsif mode == :get_and_post # with ID
          test_code << "get :#{action}, #{sanitized_params[id: 'NaID']}\n"
          test_code << "#{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          test_code << "assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          test_code << "get :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          test_code << "assert_response :success, #{show_notification}\n"
        elsif mode == :index_xhr
          test_code << "get :#{action}, #{sanitized_params[]}\n"
          test_code << "assert_response :redirect, #{show_notification}\n"
          test_code << "xhr :get, :#{action}, #{sanitized_params[]}\n"
          test_code << "assert_response :success, #{show_notification}\n"
        elsif mode == :show_xhr
          test_code << "#{record} = #{fixture_table}(:#{fixture_name}_001)\n"
          test_code << "assert #{record}.valid?, '#{fixture_name}_001 must be valid:' + #{record}.errors.inspect\n"
          test_code << "get :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          test_code << "assert_response :redirect, #{show_notification}\n"
          test_code << "xhr :get, :#{action}, #{sanitized_params[id: 'RECORD.id'.c]}\n"
          test_code << "assert_not_nil assigns(:#{record})\n"
        elsif mode == :unroll
          test_code << "xhr :get, :#{action}, #{sanitized_params[]}\n"
          test_code << "xhr :get, :#{action}, #{sanitized_params[format: :json]}\n"
          test_code << "xhr :get, :#{action}, #{sanitized_params[format: :xml]}\n"
          # TODO test all scopes
        elsif mode == :get
          test_code << "get :#{action}, #{sanitized_params[]}\n"
          test_code << "assert_response :success, #{show_notification}\n"
        elsif mode == :redirect
          test_code << "get :#{action}, #{sanitized_params[]}\n"
          test_code << "assert_response :redirect, #{show_notification}\n"
        else
          test_code << "raise StandardError, 'What is this mode? #{mode.inspect}'\n"
        end

        # code << "  should '#{action} (#{mode})' do\n"
        code << "test \"should #{action} (#{mode})\" do\n"
        # code << "  print '#{controller_name}##{action}'.green\n"
        code << test_code.dig
        code << "end\n\n"
      end
      # code << "end\n"

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
      /\#(index|new|pick|set)\z/   => :index,
      /\#(show|edit)\z/   => :show,
      /\#picture\z/       => :picture,
      /\#list\_\w+\z/     => :list_things,
      /\#list\z/          => :list,
      /\#(create|load|incorporate)\z/ => :create,
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


# Cheat Sheet
# https://gist.github.com/zhengjia/428105

# Capybara.register_driver :poltergeist do |app|
#   Capybara::Poltergeist::Driver.new(app, debug: true, inspector: true)
# end

Capybara.default_driver    = (ENV["DRIVER"] == "webkit" ? :webkit : :selenium)
Capybara.current_driver    = Capybara.default_driver
Capybara.javascript_driver = Capybara.default_driver
# Capybara.default_wait_time = 5
# Capybara.server_port = 3333

class CapybaraIntegrationTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  # # include Capybara::Screenshot
  include Warden::Test::Helpers
  Warden.test_mode!

  def shoot_screen(name = nil)
    name ||= current_url.split(/\:\d+\//).last
    sleep(1)
    file = Rails.root.join("tmp", "screenshots", "#{name}.png")
    FileUtils.mkdir_p(file.dirname) unless file.dirname.exist?
    save_page file.to_s.gsub(/\.png\z/, '.html')
    save_screenshot file # , full: true
  end

  def resize_window(width, height)
    driver = Capybara.current_driver
    if driver == :webkit
      page.window.resize_to(width, height)
    elsif driver == :selenium
      page.driver.browser.manage.window.resize_to(width, height)
    else
      raise NotImplemented, "Not implemented for #{driver.inspect}"
    end
  end

  # Add a method to test unroll in form
  # FIXME : add an AJAX helpers to capybara for testing unroll field
  # http://stackoverflow.com/questions/13187753/rails3-jquery-autocomplete-how-to-test-with-rspec-and-capybara/13213185#13213185
  # http://jackhq.tumblr.com/post/3728330919/testing-jquery-autocomplete-using-capybara
  def fill_unroll(field, options = {})
    fill_in(field, with: options[:with])
    # sleep(1)
    # page.execute_script "$('input##{field}').focus();"
    # page.execute_script "$('input##{field}').keydown();"
    shoot_screen "#{options[:name]}/unroll-before"

    # length = page.evaluate_script "$('#{selector}').length;"
    # assert_equal length >= 1, "No unrolled elements"

    script  = "$('input##{field}').next().next().find('.items-list .item"
    script << (options[:select] ? "[data-item-label~=\"#{options[:select]}\"]" : ":first-child")
    script << "').mouseenter().click();"

    # puts script.red
    page.execute_script script
    # sleep(1)
    shoot_screen "#{options[:name]}/unroll-after"
  end

end
