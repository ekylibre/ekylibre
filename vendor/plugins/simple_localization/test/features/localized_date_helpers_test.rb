require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

# Create a fake model because the +date_select+ helper needs an object to
# operate on.
class FakeModelWithDate
  
  attr_reader :date
  
  def initialize
    @date = Date.new 2007, 1, 1
  end
  
end

# Init SimpleLocalization with just the localized_date_helpers feature
# activated.
simple_localization :lang_file_dir => LANG_FILE_DIR, :language => LANG_FILE, :only => [:localized_date_helpers, :localized_date_and_time]

class LocalizedDateHelpersTest < Test::Unit::TestCase
  
  include ActionView::Helpers::DateHelper
  include ArkanisDevelopment::SimpleLocalization::LocalizedDateHelpers
  
  def test_date_select
    @record = FakeModelWithDate.new
    html_output = date_select(:record, :date)
    ArkanisDevelopment::SimpleLocalization::Language[:dates, :monthnames].each do |month_name|
      assert_contains html_output, month_name
    end
  end
  
  def test_distance_of_time_in_words
    lang = ArkanisDevelopment::SimpleLocalization::Language[:helpers, :distance_of_time_in_words]
    now, to = Time.now, 10.hours.from_now
    
    expected_output = format(lang['about n hours'], ((now - to).abs / 60 / 60).round)
    assert_equal expected_output, distance_of_time_in_words(now, to)
    assert_equal expected_output, distance_of_time_in_words_to_now(10.hours.ago)
    
    assert_equal lang['about 1 year'], distance_of_time_in_words(now, 1.year.from_now)
    [2, 3, 4, 5].each do |number_of_years|
      entry = lang["over #{number_of_years} years"] || lang['over n years']
      assert_equal format(entry, number_of_years), distance_of_time_in_words(now, number_of_years.years.from_now)
    end
    assert_equal format(lang['over n years'], 15), distance_of_time_in_words(now, 15.year.from_now)
  end
  
end
