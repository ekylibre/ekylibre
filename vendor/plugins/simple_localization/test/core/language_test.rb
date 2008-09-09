require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

# Load the specified language file and no features
simple_localization :lang_file_dir => LANG_FILE_DIR, :language => LANG_FILE, :only => []

class LanguageTest < Test::Unit::TestCase
  
  def setup
    @lang_file = YAML.load_file "#{LANG_FILE_DIR}/#{LANG_FILE}.yml"
    @lang = ArkanisDevelopment::SimpleLocalization::Language
    @lang.use LANG_FILE
  end
  
  def test_option_accessors
    @lang.options.each do |option, default_value|
      assert_equal @lang.send(option), default_value
      @lang.send "#{option}=".to_sym, 'test value'
      assert_equal @lang.send(option), 'test value'
      @lang.send "#{option}=".to_sym, default_value
    end
  end
  
  def test_entry_substitution
    assert_equal 'substitute this and 10', @lang.substitute_entry('substitute %s and %i', 'this', 10)
    assert_equal 'escape %s but not this', @lang.substitute_entry('escape %%s but not %s', 'this')
    assert_equal 'substitute this and 10', @lang.substitute_entry('substitute :a and :b', :a => 'this', :b => 10)
    assert_equal 'escape :a but not this', @lang.substitute_entry('escape \:a but not :b', :b => 'this')
    assert_equal 'substitute 0 with nothing', @lang.substitute_entry('substitute %d with nothing', nil)
    assert_nil @lang.substitute_entry(nil, 'some', 'values')
  end
  
  def test_if_language_file_is_loaded
    assert_equal LANG_FILE.to_sym, @lang.current_language
  end
  
  def test_about_lang
    info_from_class = @lang.about
    assert_equal info_from_class, @lang.about(LANG_FILE)
    @lang_file['about'].each do |key, value|
      assert_equal value, info_from_class[key.to_sym]
    end
  end
  
  def test_lang_file_access
    assert_equal @lang_file['dates']['monthnames'], @lang.find(LANG_FILE, :dates, :monthnames)
    assert_equal @lang_file['dates']['monthnames'], @lang.entry(:dates, :monthnames)
    assert_raise ArkanisDevelopment::SimpleLocalization::LangFileNotLoaded do
      @lang.find :not_loaded_lang, :dates, :monthnames
    end
  end
  
  def test_not_existing_entry_handling
    assert_nil @lang.entry(:not_existant_key)
    assert_nil @lang[:not_existant_key]
    assert_raise ArkanisDevelopment::SimpleLocalization::EntryNotFound do
      @lang.entry! :not_existant_key
      @lang.entry! :not, :existing, :entry
    end
    begin
      @lang.entry! :not, :existing, :entry
    rescue ArkanisDevelopment::SimpleLocalization::EntryNotFound => e
      assert_equal LANG_FILE.to_sym, e.language
      assert_equal %w(not existing entry), e.requested_entry
    end
  end
  
  def test_lang_file_access_with_substitution
    assert_equal 'substitute this and 10', @lang.entry(:tests, :substitution, :format, ['this', 10])
    assert_equal 'escape %s but not this', @lang.entry(:tests, :substitution, :format_escape, ['this'])
    assert_equal 'substitute this and 10', @lang.entry(:tests, :substitution, :hash, :a => 'this', :b => 10)
    assert_equal 'escape :a but not this', @lang.entry(:tests, :substitution, :hash_escape, :b => 'this')
    assert_equal @lang_file['active_record_messages']['too_long'], @lang.entry(:active_record_messages, :too_long)
    assert_nil @lang.entry(:not_existing_key, ['some', 'values'])
    assert_nil @lang.entry(:not, :existing, :key, ['some', 'values'])
    
    old_debug_mode = @lang.debug
    @lang.debug = true
    assert_raise ArkanisDevelopment::SimpleLocalization::EntryFormatError do
      @lang.entry! :tests, :substitution, :format, ['this']
    end
    @lang.debug = false
    assert_equal 'substitute %s and %i', @lang.entry!(:tests, :substitution, :format, ['this'])
    @lang.debug = old_debug_mode
  end
  
  def test_simple_lang_section_proxy
    assert_equal @lang_file['dates']['monthnames'], ArkanisDevelopment::SimpleLocalization::LangSectionProxy.new(:sections => [:dates, :monthnames])
  end
  
end
