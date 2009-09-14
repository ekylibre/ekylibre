# == Schema Information
#
# Table name: entity_links
#
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  entity1_id   :integer       not null
#  entity2_id   :integer       not null
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  nature_id    :integer       not null
#  started_on   :date          
#  stopped_on   :date          
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class EntityLinkTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
