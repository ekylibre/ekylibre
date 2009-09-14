# == Schema Information
#
# Table name: subscription_natures
#
#  actual_number         :integer       
#  comment               :text          
#  company_id            :integer       not null
#  created_at            :datetime      not null
#  creator_id            :integer       
#  entity_link_nature_id :integer       
#  id                    :integer       not null, primary key
#  lock_version          :integer       default(0), not null
#  name                  :string(255)   not null
#  nature                :string(8)     not null
#  reduction_rate        :decimal(8, 2) 
#  updated_at            :datetime      not null
#  updater_id            :integer       
#

require 'test_helper'

class SubscriptionNatureTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
