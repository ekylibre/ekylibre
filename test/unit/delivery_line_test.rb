# == Schema Information
#
# Table name: delivery_lines
#
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  creator_id        :integer       
#  delivery_id       :integer       not null
#  id                :integer       not null, primary key
#  lock_version      :integer       default(0), not null
#  order_line_id     :integer       not null
#  price_id          :integer       not null
#  product_id        :integer       not null
#  quantity          :decimal(16, 2 default(1.0), not null
#  tracking_id       :integer       
#  unit_id           :integer       not null
#  updated_at        :datetime      not null
#  updater_id        :integer       
#

require 'test_helper'

class DeliveryLineTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
