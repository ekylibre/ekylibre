# == Schema Information
#
# Table name: address_norm_items
#
#  company_id      :integer       not null
#  contact_norm_id :integer       not null
#  content         :string(255)   
#  created_at      :datetime      not null
#  creator_id      :integer       
#  id              :integer       not null, primary key
#  left_nature     :string(15)    
#  left_value      :string(63)    
#  lock_version    :integer       default(0), not null
#  maxlength       :integer       default(38), not null
#  name            :string(255)   not null
#  nature          :string(15)    default("content"), not null
#  position        :integer       
#  right_nature    :string(15)    default("space")
#  right_value     :string(63)    
#  updated_at      :datetime      not null
#  updater_id      :integer       
#

require 'test_helper'

class AddressNormItemTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
