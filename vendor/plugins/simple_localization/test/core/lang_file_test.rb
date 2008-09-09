require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class LangFileTest < Test::Unit::TestCase
  
  def setup
    @lang_file_root_dir = File.join(File.dirname(__FILE__), 'lang_file_test')
    @lang_file_dirs = %w(sl_languages another_lang_dir rails_app_languages).collect do |lang_file_dir|
      File.join(@lang_file_root_dir, lang_file_dir)
    end
    @lang_file = ArkanisDevelopment::SimpleLocalization::LangFile.new :en, @lang_file_dirs
  end
  
  def test_lookup_parts
    assert_equal @lang_file_dirs, @lang_file.lang_file_dirs
    yaml_parts, ruby_parts = @lang_file.send :lookup_parts
    
    expected_yaml_parts = {
      File.join(@lang_file_root_dir, 'sl_languages') => %w(en.yml en.part.yml en.empty.yml),
      File.join(@lang_file_root_dir, 'another_lang_dir') => %w(en.app.my_plugin.yml),
      File.join(@lang_file_root_dir, 'rails_app_languages') => %w(en.app.yml en.part.yml)
    }
    assert_equal expected_yaml_parts.keys.sort.collect{|dir| File.expand_path(dir)}, yaml_parts.keys.sort.collect{|dir| File.expand_path(dir)}
    expected_yaml_parts.each do |lang_dir, lang_files|
      assert_equal lang_files.sort, yaml_parts[lang_dir].sort
    end
    
    expected_ruby_part_order = %w(sl_languages/en.rb rails_app_languages/en.rb).collect do |part|
      File.join(@lang_file_root_dir, part)
    end
    assert_equal expected_ruby_part_order, ruby_parts
  end
  
  def test_yaml_parts_in_loading_order
    @lang_file.send :lookup_parts
    ordered_yaml_parts = @lang_file.send :yaml_parts_in_loading_order
    
    expected_part_order = [
      File.join(@lang_file_root_dir, 'sl_languages', 'en.yml'),
      File.join(@lang_file_root_dir, 'sl_languages', 'en.part.yml'),
      File.join(@lang_file_root_dir, 'sl_languages', 'en.empty.yml'),
      File.join(@lang_file_root_dir, 'another_lang_dir', 'en.app.my_plugin.yml'),
      File.join(@lang_file_root_dir, 'rails_app_languages', 'en.app.yml'),
      File.join(@lang_file_root_dir, 'rails_app_languages', 'en.part.yml')
    ]
    assert_equal expected_part_order.collect{|f| File.expand_path(f)}, ordered_yaml_parts.collect{|f| File.expand_path(f)}
  end
  
  def test_yaml_parts_in_saving_order
    @lang_file.send :lookup_parts
    ordered_yaml_parts = @lang_file.send :yaml_parts_in_saving_order
    
    expected_part_order = [
      File.join(@lang_file_root_dir, 'another_lang_dir', 'en.app.my_plugin.yml'),
      File.join(@lang_file_root_dir, 'rails_app_languages', 'en.app.yml'),
      File.join(@lang_file_root_dir, 'rails_app_languages', 'en.part.yml'),
      File.join(@lang_file_root_dir, 'sl_languages', 'en.part.yml'),
      File.join(@lang_file_root_dir, 'sl_languages', 'en.empty.yml'),
      File.join(@lang_file_root_dir, 'sl_languages', 'en.yml')
    ]
    assert_equal expected_part_order.collect{|f| File.expand_path(f)}, ordered_yaml_parts.collect{|f| File.expand_path(f)}
  end
  
  def test_load
    assert @lang_file.data.empty?, "The data of the language file isn't empty"
    $LANG_FILE_RUBY_PARTS_LOADED = []
    @lang_file.load
    
    assert !@lang_file.data.empty?, 'After loading all parts the language file data is still empty'
    assert_equal File.expand_path(File.join(@lang_file_root_dir, 'sl_languages', 'en.rb')), File.expand_path($LANG_FILE_RUBY_PARTS_LOADED.first)
    assert_equal File.expand_path(File.join(@lang_file_root_dir, 'rails_app_languages', 'en.rb')), File.expand_path($LANG_FILE_RUBY_PARTS_LOADED[1])
    
    yaml_part_data = load_all_yaml_parts_into_a_hash
    assert_equal yaml_part_data['sl_languages/en.yml']['base'], @lang_file.data['base']
    assert_equal yaml_part_data['sl_languages/en.part.yml']['sl_languages'], @lang_file.data['part', 'sl_languages']
    assert_equal yaml_part_data['rails_app_languages/en.part.yml']['rails_app_languages'], @lang_file.data['part', 'rails_app_languages']
    assert_equal yaml_part_data['rails_app_languages/en.part.yml']['description'], @lang_file.data['part', 'description']
    assert_equal yaml_part_data['rails_app_languages/en.app.yml']['title'], @lang_file.data['app', 'title']
    assert_equal yaml_part_data['another_lang_dir/en.app.my_plugin.yml']['title'], @lang_file.data['app', 'my_plugin', 'title']
  end
  
  def test_reload
    @lang_file.load
    
    new_lang_file = File.join(@lang_file_root_dir, 'rails_app_languages', 'en.yml')
    new_lang_file_content = { 'base' => 'overwritten', 'new' => 'added entry' }
    File.open(new_lang_file, 'wb') do |f|
      f.write YAML.dump(new_lang_file_content)
    end
    
    begin
      updated_memory_value = 'changed this entry in the memory data'
      new_memory_value = 'added this entry only in memory'
      @lang_file.data['base'] = updated_memory_value
      @lang_file.data['new_mem'] = new_memory_value
      
      assert_equal updated_memory_value, @lang_file.data['base']
      assert_equal new_memory_value, @lang_file.data['new_mem']
      assert_raises ArkanisDevelopment::SimpleLocalization::EntryNotFound do
        @lang_file.data['new']
      end
      
      @lang_file.reload
      
      assert_equal new_lang_file_content['base'], @lang_file.data['base']
      assert_equal new_lang_file_content['new'], @lang_file.data['new']
      assert_equal new_memory_value, @lang_file.data['new_mem']
    ensure
      File.delete new_lang_file
    end
  end
  
  def test_about
    @lang_file.load
    yaml_part_data = load_all_yaml_parts_into_a_hash
    about_data = @lang_file.about
    yaml_part_data['sl_languages/en.yml']['about'].each do |key, value|
      assert_equal value, about_data[key.to_sym]
    end
  end
  
  def test_about_without_meta_data_in_lang_file
    @lang_file.load
    @lang_file.data['about'] = nil
    assert @lang_file.about.values.compact.empty?
    
    @lang_file.data.delete 'about'
    assert @lang_file.about.values.compact.empty?
  end
  
  protected
  
  def load_all_yaml_parts_into_a_hash
    expanded_root_dir = File.expand_path(@lang_file_root_dir)
    file_hash = {}
    Dir.glob(File.join(@lang_file_root_dir, '**', '*.yml')).each do |part|
      key = File.expand_path(part).gsub("#{expanded_root_dir}/", '')
      file_hash[key] = YAML.load_file(part)
    end
    file_hash
  end
  
end
