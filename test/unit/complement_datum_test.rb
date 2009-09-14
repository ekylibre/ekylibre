# == Schema Information
#
# Table name: complement_data
#
#  boolean_value   :boolean       
#  choice_value_id :integer       
#  company_id      :integer       not null
#  complement_id   :integer       not null
#  created_at      :datetime      not null
#  creator_id      :integer       
#  date_value      :date          
#  datetime_value  :datetime      
#  decimal_value   :decimal(, )   
#  entity_id       :integer       not null
#  id              :integer       not null, primary key
#  lock_version    :integer       default(0), not null
#  string_value    :text          
#  updated_at      :datetime      not null
#  updater_id      :integer       
#

require 'test_helper'

class ComplementDatumTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
