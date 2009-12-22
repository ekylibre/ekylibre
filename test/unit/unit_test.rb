# == Schema Information
#
# Table name: units
#
#  base         :string(255)   not null
#  coefficient  :decimal(, )   default(1.0), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  label        :string(255)   not null
#  lock_version :integer       default(0), not null
#  name         :string(8)     not null
#  start        :decimal(, )   default(0.0), not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class UnitTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
