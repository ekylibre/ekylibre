# == Schema Information
#
# Table name: financialyears
#
#  closed       :boolean       not null
#  code         :string(12)    not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  started_on   :date          not null
#  stopped_on   :date          not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class FinancialyearTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
