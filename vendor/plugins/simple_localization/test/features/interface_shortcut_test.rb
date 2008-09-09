require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

# Init SimpleLocalization with just the localized_date_and_time feature
# activated.
simple_localization :lang_file_dir => LANG_FILE_DIR, :languages => [:de, :en], :only => :interface_shortcut

class InterfaceShortcutTest < Test::Unit::TestCase
  
  def test_shortcut
    assert_equal Localization, ArkanisDevelopment::SimpleLocalization::Language
    Localization.use :de
    assert_equal :de, Localization.used
    assert_equal :de, ArkanisDevelopment::SimpleLocalization::Language.used
    Localization.use :en
    assert_equal :en, Localization.used
    assert_equal :en, ArkanisDevelopment::SimpleLocalization::Language.used
    assert_equal ArkanisDevelopment::SimpleLocalization::Language.entry(:about, :language), Localization.entry(:about, :language)
  end
  
  def teardown
    ArkanisDevelopment::SimpleLocalization::Language.use LANG_FILE
  end
  
end
