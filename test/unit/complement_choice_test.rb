# == Schema Information
#
# Table name: complement_choices
#
#  company_id    :integer       not null
#  complement_id :integer       not null
#  created_at    :datetime      not null
#  creator_id    :integer       
#  id            :integer       not null, primary key
#  lock_version  :integer       default(0), not null
#  name          :string(255)   not null
#  position      :integer       
#  updated_at    :datetime      not null
#  updater_id    :integer       
#  value         :string(255)   not null
#

require 'test_helper'

class ComplementChoiceTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
