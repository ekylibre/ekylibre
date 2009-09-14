# == Schema Information
#
# Table name: employees
#
#  arrived_on       :date          
#  comment          :text          
#  commercial       :boolean       not null
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  creator_id       :integer       
#  departed_on      :date          
#  department_id    :integer       not null
#  establishment_id :integer       not null
#  first_name       :string(255)   not null
#  id               :integer       not null, primary key
#  last_name        :string(255)   not null
#  lock_version     :integer       default(0), not null
#  office           :string(32)    
#  profession_id    :integer       
#  role             :string(255)   
#  title            :string(32)    not null
#  updated_at       :datetime      not null
#  updater_id       :integer       
#  user_id          :integer       
#

require 'test_helper'

class EmployeeTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
