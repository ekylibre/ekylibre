# == Schema Information
#
# Table name: entity_natures
#
#  abbreviation :string(255)   not null
#  active       :boolean       default(TRUE), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  description  :text          
#  id           :integer       not null, primary key
#  in_name      :boolean       default(TRUE), not null
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  physical     :boolean       not null
#  title        :string(255)   
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class EntityNatureTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
