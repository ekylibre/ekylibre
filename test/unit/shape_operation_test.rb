# == Schema Information
#
# Table name: shape_operations
#
#  company_id    :integer       not null
#  consumption   :decimal(, )   
#  created_at    :datetime      not null
#  creator_id    :integer       
#  description   :text          
#  duration      :decimal(, )   
#  employee_id   :integer       not null
#  hour_duration :decimal(, )   
#  id            :integer       not null, primary key
#  lock_version  :integer       default(0), not null
#  min_duration  :decimal(, )   
#  moved_on      :date          
#  name          :string(255)   not null
#  nature_id     :integer       
#  planned_on    :date          not null
#  shape_id      :integer       not null
#  started_at    :datetime      not null
#  stopped_at    :datetime      
#  tools_list    :string(255)   
#  updated_at    :datetime      not null
#  updater_id    :integer       
#

require 'test_helper'

class ShapeOperationTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
