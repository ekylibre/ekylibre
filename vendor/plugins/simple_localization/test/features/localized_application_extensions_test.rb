require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.dirname(__FILE__) + '/../localized_application_test_helper.rb'

# Init SimpleLocalization with just the localized_date_and_time feature
# activated.
simple_localization :lang_file_dir => LANG_FILE_DIR, :language => LANG_FILE, :only => :localized_application

class LocalizedApplicationExtensionTest < Test::Unit::TestCase
  
  include LocalizedApplicationTestHelper
  
  def setup
    @lang_file = YAML.load_file "#{LANG_FILE_DIR}/#{LANG_FILE}.yml"
  end
  
  def test_l
    assert_equal @lang_file['app']['entry'], :entry.l
    assert_equal @lang_file['app']['entry'], 'entry'.l
  end
  
  def test_l_with_scope
    l_scope :entry do
      assert_equal @lang_file['app']['entry']['test'], :test.l
      assert_equal @lang_file['app']['entry']['test'], 'test'.l
    end
  end
  
  def test_substitution
    assert_equal 'test this', 'test %s'.l('this')
    assert_equal 'test this', 'test :what'.l(:what => 'this')
    assert_equal 'test this', 'test %s'.lc('this')
    assert_equal 'test this', 'test :what'.lc(:what => 'this')
  end
  
  def test_lc
    expected_values = {
      # test stack name => expected value from the language file
      :entry_model_class => 'hello model',
      :entry_model_method => 'hello model',
      :entry_observer_class => 'hello model',
      :entry_observer_method => 'hello model',
      :about_controller_class => 'hello controller',
      :about_controller_method => 'hello controller',
      :about_index_view => 'hello view',
      :shared_source_template => 'hello partial'
    }
    
    expected_values.each do |stack_name, expected_value|
      with_lc_test_stack stack_name do
        assert_equal expected_value, :test.lc, "Faild while testing get_scope_of_context with the #{stack_name} stack"
        assert_equal expected_value, 'test'.lc, "Faild while testing get_scope_of_context with the #{stack_name} stack"
      end
    end
  end
  
end
