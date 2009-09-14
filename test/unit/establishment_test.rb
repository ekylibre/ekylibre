# == Schema Information
#
# Table name: establishments
#
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  nic          :string(5)     not null
#  siret        :string(255)   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class EstablishmentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
