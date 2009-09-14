# == Schema Information
#
# Table name: sequences
#
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  creator_id       :integer       
#  format           :string(255)   not null
#  id               :integer       not null, primary key
#  last_cweek       :integer       
#  last_month       :integer       
#  last_number      :integer       
#  last_year        :integer       
#  lock_version     :integer       default(0), not null
#  name             :string(255)   not null
#  number_increment :integer       default(1), not null
#  number_start     :integer       default(1), not null
#  period           :string(255)   default("number"), not null
#  updated_at       :datetime      not null
#  updater_id       :integer       
#

require 'test_helper'

class SequenceTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
