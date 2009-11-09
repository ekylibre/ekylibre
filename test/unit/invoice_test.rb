# == Schema Information
#
# Table name: invoices
#
#  accounted          :boolean       not null
#  amount             :decimal(16, 2 default(0.0), not null
#  amount_with_taxes  :decimal(16, 2 default(0.0), not null
#  annotation         :text          
#  client_id          :integer       not null
#  company_id         :integer       not null
#  contact_id         :integer       
#  created_at         :datetime      not null
#  created_on         :date          
#  creator_id         :integer       
#  credit             :boolean       not null
#  currency_id        :integer       
#  downpayment_amount :decimal(16, 2 default(0.0), not null
#  has_downpayment    :boolean       not null
#  id                 :integer       not null, primary key
#  lock_version       :integer       default(0), not null
#  lost               :boolean       not null
#  nature             :string(1)     not null
#  number             :string(64)    not null
#  origin_id          :integer       
#  paid               :boolean       not null
#  payment_delay_id   :integer       not null
#  payment_on         :date          not null
#  sale_order_id      :integer       
#  updated_at         :datetime      not null
#  updater_id         :integer       
#

require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
