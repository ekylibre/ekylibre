# == Schema Information
#
# Table name: contacts
#
#  active       :boolean       not null
#  address      :string(280)   
#  area_id      :integer       
#  closed_on    :date          
#  code         :string(4)     
#  company_id   :integer       not null
#  country      :string(2)     
#  created_at   :datetime      not null
#  creator_id   :integer       
#  default      :boolean       not null
#  deleted      :boolean       not null
#  email        :string(255)   
#  entity_id    :integer       not null
#  fax          :string(32)    
#  id           :integer       not null, primary key
#  latitude     :float         
#  line_2       :string(38)    
#  line_3       :string(38)    
#  line_4       :string(48)    
#  line_5       :string(38)    
#  line_6       :string(255)   
#  lock_version :integer       default(0), not null
#  longitude    :float         
#  mobile       :string(32)    
#  phone        :string(32)    
#  started_at   :datetime      
#  stopped_at   :datetime      
#  updated_at   :datetime      not null
#  updater_id   :integer       
#  website      :string(255)   
#

require 'test_helper'

class ContactTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
