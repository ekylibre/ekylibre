require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

# Init SimpleLocalization with just the localized_error_messages feature
# activated.
simple_localization :lang_file_dir => LANG_FILE_DIR, :language => LANG_FILE, :only => :localized_error_messages

class LocalizedErrorMessagesTest < Test::Unit::TestCase
  
  def test_error_message_constants
    ActiveRecord::Errors.default_error_messages.each do |key, msg|
      assert_equal msg, ArkanisDevelopment::SimpleLocalization::Language[:active_record_messages, key]
    end
  end
  
end
