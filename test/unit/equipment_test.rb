# == Schema Information
#
# Table name: equipment
#
#  company_id   :integer       not null
#  consumption  :decimal(, )   
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  nature       :string(8)     not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class EquipmentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
