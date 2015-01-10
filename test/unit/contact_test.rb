# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: contacts
#
#  address      :string(280)      
#  area_id      :integer          
#  by_default   :boolean          not null
#  code         :string(4)        
#  company_id   :integer          not null
#  country      :string(2)        
#  created_at   :datetime         not null
#  creator_id   :integer          
#  deleted_at   :datetime         
#  email        :string(255)      
#  entity_id    :integer          not null
#  fax          :string(32)       
#  id           :integer          not null, primary key
#  latitude     :float            
#  line_2       :string(38)       
#  line_3       :string(38)       
#  line_4       :string(48)       
#  line_5       :string(38)       
#  line_6       :string(255)      
#  lock_version :integer          default(0), not null
#  longitude    :float            
#  mobile       :string(32)       
#  phone        :string(32)       
#  updated_at   :datetime         not null
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
