require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

# Init SimpleLocalization with localized_model_attributes feature.
# It loads localized_number_helpers and localized_date_and_time
# features which are needed for conversion between native and local number formats.

simple_localization :lang_file_dir => LANG_FILE_DIR, :language => LANG_FILE, :only => [:localized_model_attributes]

# Create a tableless model. See Rails Weenie:
# http://www.railsweenie.com/forums/2/topics/724
class Dinosaur < ActiveRecord::Base

  def self.columns() @columns ||= []; end
  def self.column(name, sql_type = nil, default = nil, null = true)
    column = ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
    columns << column
    column
  end

  column :size,       :float
  column :extinct_on, :date
  column :created_at, :datetime
  column :population, :integer
  column :name,       :string

  column(:strength, :decimal).instance_variable_set(:@scale, 2)
end

class LocalizedModelAttributesTest < Test::Unit::TestCase
  include ActionView::Helpers::NumberHelper

  # These are available because localized_model_attributes loades them.
  if Rails::VERSION::MAJOR == 1 and Rails::VERSION::MINOR == 1
    include ArkanisDevelopment::SimpleLocalization::LocalizedNumberHelpers::Rails11
  else
    include ArkanisDevelopment::SimpleLocalization::LocalizedNumberHelpers::Rails12
  end

  def setup
    @trex = Dinosaur.new :strength => 2012.90, :extinct_on => Date.new(1985, 8, 15), :size => 10.89, :population => 2000, :name => 'T-Rex', :created_at => Time.now
  end

  def test_decimal_reader_localized
    assert_equal number_with_delimiter(number_with_precision(@trex.strength, 2)), @trex.strength_localized
  end

  def test_float_reader_localized
    assert_equal number_with_delimiter(@trex.size), @trex.size_localized
  end

  def test_integer_reader_localized
    assert_equal number_with_delimiter(@trex.population), @trex.population_localized
  end

  def test_date_reader_localized
    assert_equal @trex.extinct_on.to_formatted_s(:attributes), @trex.extinct_on_localized
  end

  def test_datetime_reader_localized
    assert_equal @trex.created_at.to_formatted_s(:attributes), @trex.created_at_localized
  end

  def test_decimal_writer_localized
    new_strength = BigDecimal.new('1999.23')
    @trex.strength_localized = number_with_delimiter(new_strength)
    assert_equal new_strength, @trex.strength
  end

  def test_float_writer_localized
    new_size = 100.02
    @trex.size_localized = number_with_delimiter(new_size)
    assert_equal new_size, @trex.size
  end

  def test_integer_writer_localized
    new_population = 3321
    @trex.population_localized = number_with_delimiter(new_population)
    assert_equal new_population, @trex.population
  end

  def test_date_writer_localized
    new_extinct_on = Date.new(1977, 12, 9)
    @trex.extinct_on_localized = new_extinct_on.to_formatted_s(:attributes)
    assert_equal new_extinct_on, @trex.extinct_on
  end

  def test_datetime_writer_localized
    # caution: this assumes that the +attributes+ format includes hours and minutes!
    new_created_at = DateTime.civil(1980, 4, 2, 8, 16).to_time
    @trex.created_at_localized = new_created_at.to_formatted_s(:attributes)
    assert_equal new_created_at, @trex.created_at
  end

  def test_non_localizable_attributes
    assert_equal @trex.name_localized, @trex.name
    new_name = 'Utahraptor'
    @trex.name_localized = new_name
    assert_equal new_name, @trex.name
  end

  def test_invalid_date_format_should_raise_argument_error
    assert_raise ArgumentError do
      @trex.extinct_on_localized = 'foo bar'
    end
  end

  def test_blank_date_value_should_not_raise_and_set_attribute_to_nil
    assert_nothing_raised do
      @trex.extinct_on_localized = ''
    end

    assert_nil @trex.extinct_on_localized
  end

  def test_blank_number_value_should_set_attribute_to_nil
    @trex.strength_localized = nil
    @trex.population_localized = ''
    assert_nil @trex.strength
    assert_nil @trex.population
  end

  def test_empty_attributes_should_not_be_localized
    @trex.population = nil
    @trex.strength = nil
    @trex.extinct_on_localized = nil
    assert_nil @trex.population_localized
    assert_nil @trex.strength_localized
    assert_nil @trex.extinct_on_localized
  end
end
