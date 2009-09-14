# == Schema Information
#
# Table name: parameters
#
#  boolean_value     :boolean       
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  creator_id        :integer       
#  decimal_value     :decimal(, )   
#  id                :integer       not null, primary key
#  integer_value     :integer       
#  lock_version      :integer       default(0), not null
#  name              :string(255)   not null
#  nature            :string(8)     default("u"), not null
#  record_value_id   :integer       
#  record_value_type :string(255)   
#  string_value      :text          
#  updated_at        :datetime      not null
#  updater_id        :integer       
#  user_id           :integer       
#

require 'test_helper'

class ParameterTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
