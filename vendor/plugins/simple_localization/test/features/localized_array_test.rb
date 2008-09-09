require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

# Init SimpleLocalization with just the localized_date_and_time feature
# activated.
simple_localization :lang_file_dir => LANG_FILE_DIR, :language => LANG_FILE, :only => :localized_array

class LocalizedArrayTest < Test::Unit::TestCase
  
  def test_to_sentence
    test_array = ['a', 'b', 'c']
    options = ArkanisDevelopment::SimpleLocalization::Language[:arrays, :to_sentence].symbolize_keys
    correct_output = "#{test_array[0...-1].join(', ')}#{options[:skip_last_comma] ? '' : ','} #{options[:connector]} #{test_array[-1]}"
    assert_equal test_array.to_sentence, correct_output
  end
  
end
