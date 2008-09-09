require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

simple_localization :lang_file_dir => LANG_FILE_DIR, :language => LANG_FILE, :only => :localized_number_helpers

class LocalizedNumberHelpersTest < Test::Unit::TestCase
  
  include ActionView::Helpers::NumberHelper
  
  if Rails::VERSION::MAJOR == 1 and Rails::VERSION::MINOR == 1
    include ArkanisDevelopment::SimpleLocalization::LocalizedNumberHelpers::Rails11
  else
    include ArkanisDevelopment::SimpleLocalization::LocalizedNumberHelpers::Rails12
  end
  include ArkanisDevelopment::SimpleLocalization::LocalizedNumberHelpers::RailsCommon
  
  def setup
    @lang = ArkanisDevelopment::SimpleLocalization::Language
  end
  
  def test_number_to_currency
    assert_equal '1.500,49 €', number_to_currency(1500.49, :precision => 2, :unit => ' €', :separator => ',', :delimiter => '.', :order => [:main, :separator, :fraction, :unit])
  end
  
  def test_number_to_percentage
    assert_equal "100,00%", number_to_percentage(100, :precision => 2, :separator => ',')
  end
  
  def test_number_to_phone
    assert_equal "123 555 1234", number_to_phone(1235551234, :area_code => false, :delimiter => ' ', :extension => '')
  end
  
  def test_number_with_delimiter
    delimiter = @lang[:numbers, :delimiter]
    assert_equal "12#{delimiter}345#{delimiter}678", number_with_delimiter(12345678)
  end
  
  def test_number_with_precision
    assert_equal "100#{@lang[:numbers, :separator]}49", number_with_precision(100.49, 2)
  end
  
end
