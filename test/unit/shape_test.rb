# == Schema Information
#
# Table name: shapes
#
#  area         :decimal(, )   default(0.0), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  description  :text          
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  master       :boolean       default(TRUE), not null
#  name         :string(255)   not null
#  number       :string(255)   
#  parent_id    :integer       
#  polygon      :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class ShapeTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
