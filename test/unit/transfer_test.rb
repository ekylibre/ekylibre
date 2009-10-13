# == Schema Information
#
# Table name: transfers
#
#  amount       :decimal(16, 2 default(0.0), not null
#  comment      :string(255)   
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  label        :string(255)   
#  lock_version :integer       default(0), not null
#  parts_amount :decimal(16, 2 default(0.0), not null
#  started_on   :date          
#  stopped_on   :date          
#  supplier_id  :integer       
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class TransferTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
