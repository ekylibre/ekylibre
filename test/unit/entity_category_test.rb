# == Schema Information
#
# Table name: entity_categories
#
#  code         :string(8)     
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  default      :boolean       not null
#  deleted      :boolean       not null
#  description  :text          
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class EntityCategoryTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
