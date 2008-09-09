require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

# Init SimpleLocalization with just the localized_date_and_time feature
# activated.
simple_localization :lang_file_dir => LANG_FILE_DIR, :language => LANG_FILE, :only => :localized_date_and_time

class LocalizedDatesTest < Test::Unit::TestCase
  
  def setup
    @language = ArkanisDevelopment::SimpleLocalization::Language
    @tools = ArkanisDevelopment::SimpleLocalization::LocalizedDateAndTime
    @test_date = Date.new 2007, 1, 1
    @test_time = Time.utc 2007, 1, 1
  end
  
  def test_date_constants
    assert_equal Date::MONTHNAMES, [nil] + @language[:dates, :monthnames]
    assert_equal Date::DAYNAMES, @language[:dates, :daynames]
    assert_equal Date::ABBR_MONTHNAMES, [nil] +  @language[:dates, :abbr_monthnames]
    assert_equal Date::ABBR_DAYNAMES, @language[:dates, :abbr_daynames]
    
    assert_equal Date::MONTHS, @tools.convert_to_name_indexed_hash(@language[:dates, :monthnames], 1)
    assert_equal Date::DAYS, @tools.convert_to_name_indexed_hash(@language[:dates, :daynames], 0)
    assert_equal Date::ABBR_MONTHS, @tools.convert_to_name_indexed_hash(@language[:dates, :abbr_monthnames], 1)
    assert_equal Date::ABBR_DAYS, @tools.convert_to_name_indexed_hash(@language[:dates, :abbr_daynames], 0)
  end
  
  def test_date_strftime
    #  strftime format meaning:
    #  
    #  %a - The abbreviated weekday name (``Sun'')
    #  %A - The  full  weekday  name (``Sunday'')
    #  %b - The abbreviated month name (``Jan'')
    #  %B - The  full  month  name (``January'')
    
    assert_equal @language[:dates, :abbr_daynames][1], @test_date.strftime('%a')
    assert_equal " #{@language[:dates, :daynames][1]} ", @test_date.strftime(' %A ')
    assert_equal @language[:dates, :abbr_monthnames][0], @test_date.strftime('%b')
    assert_equal @language[:dates, :monthnames][0], @test_date.strftime('%B')
    assert_equal '%B', @test_date.strftime('%%B')
  end
  
  def test_date_conversions
    @language[:dates, :date_formats].each do |name, format|
      assert_equal @test_date.strftime(format), @test_date.to_formatted_s(name.to_sym)
    end
  end
  
  def test_time_strftime
    #  strftime format meaning:
    #  
    #  %a - The abbreviated weekday name (``Sun'')
    #  %A - The  full  weekday  name (``Sunday'')
    #  %b - The abbreviated month name (``Jan'')
    #  %B - The  full  month  name (``January'')
    
    assert_equal @language[:dates, :abbr_daynames][1], @test_time.strftime('%a')
    assert_equal " #{@language[:dates, :daynames][1]} ", @test_time.strftime(' %A ')
    assert_equal @language[:dates, :abbr_monthnames][0], @test_time.strftime('%b')
    assert_equal @language[:dates, :monthnames][0], @test_time.strftime('%B')
    assert_equal '%B', @test_time.strftime('%%B')
  end
  
  def test_time_conversions
    @language[:dates, :time_formats].each do |name, format|
      assert_equal @test_time.strftime(format).strip, @test_time.to_formatted_s(name.to_sym)
    end
  end
  
  def test_strftime_overwrites
    assert_equal @test_date.strftime(@language[:dates, :strftime_overwrites, :x]), @test_date.strftime('%x')
    assert_equal @test_time.strftime(@language[:dates, :strftime_overwrites, :x]), @test_time.strftime('%x')
  end
  
  # Cover a bug caused by the wrong default value of the Date#strftime method
  def test_to_s
    assert_nothing_raised do
      @test_date.to_s
      @test_time.to_s
    end
  end
  
end
