# == Schema Information
#
# Table name: sale_order_natures
#
#  active              :boolean       default(TRUE), not null
#  comment             :text          
#  company_id          :integer       not null
#  created_at          :datetime      not null
#  creator_id          :integer       
#  downpayment         :boolean       not null
#  downpayment_minimum :decimal(16, 2 default(0.0), not null
#  downpayment_rate    :decimal(16, 2 default(0.0), not null
#  expiration_id       :integer       not null
#  id                  :integer       not null, primary key
#  lock_version        :integer       default(0), not null
#  name                :string(255)   not null
#  payment_delay_id    :integer       not null
#  payment_type        :string(8)     
#  updated_at          :datetime      not null
#  updater_id          :integer       
#

require 'test_helper'

class SaleOrderNatureTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
