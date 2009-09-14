# == Schema Information
#
# Table name: document_natures
#
#  code         :string(255)   not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  family       :string(255)   
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  to_archive   :boolean       not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class DocumentNatureTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
