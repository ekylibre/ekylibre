require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

# Init SimpleLocalization with just the localized_models and
# localized_error_messages features enabled. The localized_error_messages
# feature is enabled to have fully localized error messages.
simple_localization :lang_file_dir => LANG_FILE_DIR, :language => LANG_FILE, :only => [:localized_models, :localized_column_human_name, :localized_error_messages, :localized_active_record_helpers]

# Localized names for the model and it's attributes.
# The city and state attribute are commented out to test attributes with no
# localization data.
CONTACT_MODEL_NAME = 'Der Kontakt'
CONTACT_ATTRIBUTE_NAMES = {
  :name => 'Der Name',
  # :city => 'Die Stadt',
  # :state => 'Der Staat',
  :phone => 'Die Telefon-Nummer',
  :email_address => 'Die eMail-Adresse'
}

# Create a tableless model. See Rails Weenie:
# http://www.railsweenie.com/forums/2/topics/724
class Contact < ActiveRecord::Base
  
  def self.columns() @columns ||= []; end
  def self.column(name, sql_type = nil, default = nil, null = true)
    column = ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
    column.model_class = self
    columns << column
  end
  
  column :name,          :string
  column :city,          :string
  column :state,         :string
  column :phone,         :string
  column :email_address, :string
  
  validates_presence_of :name, :email_address
  
  localized_names CONTACT_MODEL_NAME, CONTACT_ATTRIBUTE_NAMES
  
end

class LocalizedModelsTest < Test::Unit::TestCase
  
  include ActionView::Helpers::TagHelper
  
  if Rails::VERSION::MAJOR == 1 and Rails::VERSION::MINOR == 1
    include ArkanisDevelopment::SimpleLocalization::LocalizedActiveRecordHelpers::Rails11
  else
    include ArkanisDevelopment::SimpleLocalization::LocalizedActiveRecordHelpers::Rails12
  end
  
  def setup
    @contact = Contact.new :name => 'Stephan Soller',
                           :city => 'HomeSweetHome',
                           :phone => '12345'
  end
  
  def test_model_and_attribute_names
    assert_equal Contact.localized_model_name, CONTACT_MODEL_NAME
    assert_equal Contact.human_attribute_name(:name), CONTACT_ATTRIBUTE_NAMES[:name]
  end
  
  def test_localized_error_messages
    assert_equal @contact.valid?, false
    assert_equal @contact.errors.full_messages.size, 1
    assert_equal @contact.errors.full_messages.first, CONTACT_ATTRIBUTE_NAMES[:email_address] + ' ' + ArkanisDevelopment::SimpleLocalization::Language[:active_record_messages, :blank]
  end
  
  def test_localized_active_record_helpers
    assert_equal @contact.valid?, false
    html_output = error_messages_for :contact
    localized_title = ArkanisDevelopment::SimpleLocalization::Language[:helpers, :error_messages_for, :heading, 1]
    
    assert_contains html_output, format(localized_title, 1, CONTACT_MODEL_NAME)
    assert_contains html_output, ArkanisDevelopment::SimpleLocalization::Language[:helpers, :error_messages_for, :description]
    assert_contains html_output, CONTACT_ATTRIBUTE_NAMES[:email_address] + ' ' + ArkanisDevelopment::SimpleLocalization::Language[:active_record_messages, :blank]
  end
  
  # This tests the extended Column class. It now holds a reference to the model
  # class the column belongs to and is using it to call human_attribute_name on
  # the proper class (see extensions/localized_column_human_name.rb).
  def test_column_human_name
    assert_equal CONTACT_ATTRIBUTE_NAMES[:name], Contact.columns.find{|c| c.name == 'name'}.human_name
  end
  
end
