# == Schema Information
#
# Table name: document_templates
#
#  active       :boolean       not null
#  cache        :text          
#  company_id   :integer       not null
#  country      :string(2)     
#  created_at   :datetime      not null
#  creator_id   :integer       
#  deleted      :boolean       not null
#  id           :integer       not null, primary key
#  language_id  :integer       
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  nature_id    :integer       not null
#  source       :text          
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

require 'test_helper'

class PrintTemplateTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
