# == Schema Information
#
# Table name: product_components
#
#  active       :boolean       not null
#  comment      :text          
#  company_id   :integer       not null
#  component_id :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  location_id  :integer       not null
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  product_id   :integer       not null
#  quantity     :decimal(16, 2 not null
#  started_at   :datetime      
#  stopped_at   :datetime      
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class ProductComponentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
