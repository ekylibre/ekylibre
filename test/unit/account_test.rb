# == Schema Information
#
# Table name: accounts
#
#  alpha        :string(16)    
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  deleted      :boolean       not null
#  groupable    :boolean       not null
#  id           :integer       not null, primary key
#  is_debit     :boolean       not null
#  keep_entries :boolean       not null
#  label        :string(255)   not null
#  last_letter  :string(8)     
#  letterable   :boolean       not null
#  lock_version :integer       default(0), not null
#  name         :string(208)   not null
#  number       :string(16)    not null
#  parent_id    :integer       default(0), not null
#  pointable    :boolean       not null
#  transferable :boolean       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#  usable       :boolean       not null
#

require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
