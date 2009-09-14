# == Schema Information
#
# Table name: departments
#
#  comment          :text          
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  creator_id       :integer       
#  id               :integer       not null, primary key
#  lock_version     :integer       default(0), not null
#  name             :string(255)   not null
#  parent_id        :integer       
#  sales_conditions :text          
#  updated_at       :datetime      not null
#  updater_id       :integer       
#

require 'test_helper'

class DepartmentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
