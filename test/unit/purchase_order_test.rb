# == Schema Information
#
# Table name: purchase_orders
#
#  amount            :decimal(16, 2 default(0.0), not null
#  amount_with_taxes :decimal(16, 2 default(0.0), not null
#  comment           :text          
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  created_on        :date          
#  creator_id        :integer       
#  dest_contact_id   :integer       
#  id                :integer       not null, primary key
#  invoiced          :boolean       not null
#  lock_version      :integer       default(0), not null
#  moved_on          :date          
#  number            :string(64)    not null
#  planned_on        :date          
#  shipped           :boolean       not null
#  supplier_id       :integer       not null
#  updated_at        :datetime      not null
#  updater_id        :integer       
#

require 'test_helper'

class PurchaseOrderTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
