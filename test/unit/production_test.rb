# == Schema Information
#
# Table name: productions
#
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  location_id  :integer       not null
#  lock_version :integer       default(0), not null
#  moved_on     :date          not null
#  planned_on   :date          not null
#  product_id   :integer       not null
#  quantity     :decimal(16, 2 default(0.0), not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class ProductionTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
