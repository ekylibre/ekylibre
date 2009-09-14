# == Schema Information
#
# Table name: languages
#
#  company_id   :integer       
#  created_at   :datetime      
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  iso2         :string(2)     not null
#  iso3         :string(3)     not null
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  native_name  :string(255)   not null
#  updated_at   :datetime      
#  updater_id   :integer       
#

require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
