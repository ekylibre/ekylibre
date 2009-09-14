# == Schema Information
#
# Table name: stock_moves
#
#  comment            :text          
#  company_id         :integer       not null
#  created_at         :datetime      not null
#  creator_id         :integer       
#  generated          :boolean       
#  id                 :integer       not null, primary key
#  input              :boolean       
#  location_id        :integer       not null
#  lock_version       :integer       default(0), not null
#  moved_on           :date          
#  name               :string(255)   not null
#  origin_id          :integer       
#  origin_type        :string(255)   
#  planned_on         :date          not null
#  product_id         :integer       not null
#  quantity           :float         not null
#  second_location_id :integer       
#  second_move_id     :integer       
#  tracking_id        :integer       
#  unit_id            :integer       not null
#  updated_at         :datetime      not null
#  updater_id         :integer       
#  virtual            :boolean       
#

require 'test_helper'

class StockMoveTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
