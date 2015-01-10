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
# == Table: users
#
#  admin             :boolean          default(TRUE), not null
#  arrived_on        :date             
#  comment           :text             
#  commercial        :boolean          
#  company_id        :integer          not null
#  connected_at      :datetime         
#  created_at        :datetime         not null
#  creator_id        :integer          
#  departed_on       :date             
#  department_id     :integer          
#  email             :string(255)      
#  employed          :boolean          not null
#  employment        :string(255)      
#  establishment_id  :integer          
#  first_name        :string(255)      not null
#  hashed_password   :string(64)       
#  id                :integer          not null, primary key
#  language          :string(3)        default("???"), not null
#  last_name         :string(255)      not null
#  lock_version      :integer          default(0), not null
#  locked            :boolean          not null
#  name              :string(32)       not null
#  office            :string(255)      
#  profession_id     :integer          
#  reduction_percent :decimal(16, 4)   default(5.0), not null
#  rights            :text             
#  role_id           :integer          not null
#  salt              :string(64)       
#  updated_at        :datetime         not null
#  updater_id        :integer          
#


require 'test_helper'

class UserTest < ActiveSupport::TestCase
  
  test "the validity of rights.yml" do
    rights = nil
    assert_nothing_raised do
      rights = YAML.load_file(User.rights_file)
    end
  end



end
