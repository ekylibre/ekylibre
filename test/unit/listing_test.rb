# == Schema Information
#
# Table name: listings
#
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  query        :text          
#  root_model   :string(255)   not null
#  story        :text          
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class ListingTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
