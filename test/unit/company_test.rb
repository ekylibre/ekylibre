# == Schema Information
#
# Table name: companies
#
#  born_on          :date          
#  code             :string(8)     not null
#  created_at       :datetime      not null
#  creator_id       :integer       
#  deleted          :boolean       not null
#  entity_id        :integer       
#  id               :integer       not null, primary key
#  lock_version     :integer       default(0), not null
#  locked           :boolean       not null
#  name             :string(255)   not null
#  sales_conditions :text          
#  updated_at       :datetime      not null
#  updater_id       :integer       
#

require 'test_helper'

class CompanyTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
