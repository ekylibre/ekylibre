# == Schema Information
#
# Table name: invoice_lines
#
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  annotation        :text          
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  creator_id        :integer       
#  entity_id         :integer       
#  id                :integer       not null, primary key
#  invoice_id        :integer       
#  lock_version      :integer       default(0), not null
#  order_line_id     :integer       
#  origin_id         :integer       
#  position          :integer       
#  price_id          :integer       not null
#  product_id        :integer       not null
#  quantity          :decimal(16, 2 default(1.0), not null
#  updated_at        :datetime      not null
#  updater_id        :integer       
#

require 'test_helper'

class InvoiceLineTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
