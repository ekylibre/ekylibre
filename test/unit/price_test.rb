# == Schema Information
#
# Table name: prices
#
#  active            :boolean       default(TRUE), not null
#  amount            :decimal(16, 4 not null
#  amount_with_taxes :decimal(16, 4 not null
#  category_id       :integer       
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  creator_id        :integer       
#  currency_id       :integer       
#  default           :boolean       default(TRUE)
#  entity_id         :integer       
#  id                :integer       not null, primary key
#  lock_version      :integer       default(0), not null
#  product_id        :integer       not null
#  quantity_max      :decimal(16, 2 default(0.0), not null
#  quantity_min      :decimal(16, 2 default(0.0), not null
#  started_at        :datetime      
#  stopped_at        :datetime      
#  tax_id            :integer       not null
#  updated_at        :datetime      not null
#  updater_id        :integer       
#  use_range         :boolean       not null
#

require 'test_helper'

class PriceTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
