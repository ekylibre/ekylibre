require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

simple_localization :lang_file_dir => LANG_FILE_DIR, :language => LANG_FILE, :only => [:extended_error_messages, :localized_error_messages, :localized_models]

DOG_MODEL_NAME = 'Der Hund'
DOG_ATTRIBUTE_NAMES = {
  :name => 'Der Name',
  :short_name => 'Der Kurzname',
  :age => 'Das Alter'
}

# Create a tableless model. See Rails Weenie:
# http://www.railsweenie.com/forums/2/topics/724
class Dog < ActiveRecord::Base
  
  def self.columns() @columns ||= []; end
  def self.column(name, sql_type = nil, default = nil, null = true)
    column = ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
    columns << column
  end
  
  column :name, :string
  column :short_name, :string
  column :age,  :integer
  
  validates_presence_of :name, :message => 'vom Model :model darf nicht leer sein.'
  validates_length_of :short_name, :maximum => 5, :message => 'Das Attribut :attr ist zu lang (maximal %d Zeichen).'
  validates_numericality_of :age, :only_integer => true, :message => 'Das Attribut :attr vom Model :model ist keine Zahl.'
  
  localized_names DOG_MODEL_NAME, DOG_ATTRIBUTE_NAMES
  
end

class ExtendedErrorMessagesTest < Test::Unit::TestCase
  
  def test_model_and_attr_substitution
    dog = Dog.new
    assert_equal false, dog.valid?
    
    name_error, short_name_error, age_error = dog.errors.full_messages
    assert_equal 'Der Name vom Model Der Hund darf nicht leer sein.', name_error
    assert_equal 'Das Attribut Der Kurzname ist zu lang (maximal 5 Zeichen).', short_name_error
    assert_equal 'Das Attribut Das Alter vom Model Der Hund ist keine Zahl.', age_error
  end
  
end
