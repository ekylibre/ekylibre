# == Schema Information
#
# Table name: listing_node_items
#
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  nature       :string(8)     not null
#  node_id      :integer       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#  value        :text          
#

require 'test_helper'

class ListingNodeItemTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
