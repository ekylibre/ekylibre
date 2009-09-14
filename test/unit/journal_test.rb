# == Schema Information
#
# Table name: journals
#
#  closed_on      :date          default(CURRENT_DATE), not null
#  code           :string(4)     not null
#  company_id     :integer       not null
#  counterpart_id :integer       
#  created_at     :datetime      not null
#  creator_id     :integer       
#  currency_id    :integer       not null
#  deleted        :boolean       not null
#  id             :integer       not null, primary key
#  lock_version   :integer       default(0), not null
#  name           :string(255)   not null
#  nature         :string(16)    not null
#  updated_at     :datetime      not null
#  updater_id     :integer       
#

require 'test_helper'

class JournalTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
