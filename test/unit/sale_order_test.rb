# == Schema Information
#
# Table name: sale_orders
#
#  accounted           :boolean       not null
#  amount              :decimal(16, 2 default(0.0), not null
#  amount_with_taxes   :decimal(16, 2 default(0.0), not null
#  annotation          :text          
#  client_id           :integer       not null
#  comment             :text          
#  company_id          :integer       not null
#  conclusion          :text          
#  confirmed_on        :date          
#  contact_id          :integer       
#  created_at          :datetime      not null
#  created_on          :date          not null
#  creator_id          :integer       
#  currency_id         :integer       
#  delivery_contact_id :integer       
#  downpayment_amount  :decimal(16, 2 default(0.0), not null
#  expiration_id       :integer       not null
#  expired_on          :date          not null
#  function_title      :string(255)   
#  has_downpayment     :boolean       not null
#  id                  :integer       not null, primary key
#  introduction        :text          
#  invoice_contact_id  :integer       
#  invoiced            :boolean       not null
#  letter_format       :boolean       default(TRUE), not null
#  lock_version        :integer       default(0), not null
#  nature_id           :integer       not null
#  number              :string(64)    not null
#  parts_amount        :decimal(16, 2 
#  payment_delay_id    :integer       not null
#  responsible_id      :integer       
#  state               :string(1)     default("O"), not null
#  subject             :string(255)   
#  sum_method          :string(8)     default("wt"), not null
#  transporter_id      :integer       
#  updated_at          :datetime      not null
#  updater_id          :integer       
#

require 'test_helper'

class SaleOrderTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
