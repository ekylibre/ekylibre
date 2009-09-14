# == Schema Information
#
# Table name: taxes
#
#  account_collected_id :integer       
#  account_paid_id      :integer       
#  amount               :decimal(16, 4 default(0.0), not null
#  company_id           :integer       not null
#  created_at           :datetime      not null
#  creator_id           :integer       
#  deleted              :boolean       not null
#  description          :text          
#  id                   :integer       not null, primary key
#  included             :boolean       not null
#  lock_version         :integer       default(0), not null
#  name                 :string(255)   not null
#  nature               :string(8)     not null
#  reductible           :boolean       default(TRUE), not null
#  updated_at           :datetime      not null
#  updater_id           :integer       
#

require 'test_helper'

class TaxTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
