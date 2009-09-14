# == Schema Information
#
# Table name: stock_trackings
#
#  active       :boolean       default(TRUE), not null
#  begun_at     :datetime      not null
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  serial       :string(255)   
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class StockTrackingTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
