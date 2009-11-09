# == Schema Information
#
# Table name: entries
#
#  account_id      :integer       not null
#  comment         :text          
#  company_id      :integer       not null
#  created_at      :datetime      not null
#  creator_id      :integer       
#  credit          :decimal(16, 2 default(0.0), not null
#  currency_credit :decimal(16, 2 default(0.0), not null
#  currency_debit  :decimal(16, 2 default(0.0), not null
#  currency_id     :integer       not null
#  currency_rate   :decimal(16, 6 not null
#  debit           :decimal(16, 2 default(0.0), not null
#  draft           :boolean       not null
#  editable        :boolean       default(TRUE)
#  expired_on      :date          
#  id              :integer       not null, primary key
#  intermediate_id :integer       
#  letter          :string(8)     
#  lock_version    :integer       default(0), not null
#  name            :string(255)   not null
#  position        :integer       
#  record_id       :integer       not null
#  statement_id    :integer       
#  updated_at      :datetime      not null
#  updater_id      :integer       
#

require 'test_helper'

class EntryTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
