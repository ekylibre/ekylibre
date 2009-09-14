# == Schema Information
#
# Table name: complements
#
#  active       :boolean       default(TRUE), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  decimal_max  :decimal(16, 4 
#  decimal_min  :decimal(16, 4 
#  id           :integer       not null, primary key
#  length_max   :integer       
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  nature       :string(8)     not null
#  position     :integer       
#  required     :boolean       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class ComplementTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
