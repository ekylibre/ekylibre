# == Schema Information
#
# Table name: shape_operation_lines
#
#  area_unit_id       :integer       
#  company_id         :integer       not null
#  created_at         :datetime      not null
#  creator_id         :integer       
#  id                 :integer       not null, primary key
#  lock_version       :integer       default(0), not null
#  product_id         :integer       
#  product_unit_id    :integer       
#  quantity           :decimal(, )   default(0.0), not null
#  shape_operation_id :integer       not null
#  tracking_id        :integer       
#  unit_quantity      :decimal(, )   default(0.0), not null
#  updated_at         :datetime      not null
#  updater_id         :integer       
#

require 'test_helper'

class ShapeOperationLineTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
