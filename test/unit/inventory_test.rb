# == Schema Information
#
# Table name: inventories
#
#  changes_reflected :boolean       
#  comment           :text          
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  creator_id        :integer       
#  date              :date          not null
#  id                :integer       not null, primary key
#  lock_version      :integer       default(0), not null
#  updated_at        :datetime      not null
#  updater_id        :integer       
#

require 'test_helper'

class InventoryTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
