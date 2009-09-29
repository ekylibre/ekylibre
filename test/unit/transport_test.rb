# == Schema Information
#
# Table name: transports
#
#  comment        :text          
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  created_on     :date          
#  creator_id     :integer       
#  id             :integer       not null, primary key
#  lock_version   :integer       default(0), not null
#  transporter_id :integer       not null
#  updated_at     :datetime      not null
#  updater_id     :integer       
#  weight         :decimal(, )   
#

require 'test_helper'

class TransportTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end
