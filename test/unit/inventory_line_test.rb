# == Schema Information
#
# Table name: inventory_lines
#
#  company_id         :integer       not null
#  created_at         :datetime      not null
#  creator_id         :integer       
#  id                 :integer       not null, primary key
#  inventory_id       :integer       not null
#  location_id        :integer       not null
#  lock_version       :integer       default(0), not null
#  product_id         :integer       not null
#  theoric_quantity   :decimal(16, 2 not null
#  updated_at         :datetime      not null
#  updater_id         :integer       
#  validated_quantity :decimal(16, 2 not null
#

require 'test_helper'

class InventoryLineTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
