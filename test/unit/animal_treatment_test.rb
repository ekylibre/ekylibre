# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: animal_treatments
#
#  created_at                  :datetime         not null
#  creator_id                  :integer          
#  disease_id                  :integer          
#  drug_admission_path         :string(255)      
#  drug_id                     :integer          
#  duration                    :decimal(19, 4)   
#  duration_unit_wait_for_meat :string(255)      
#  duration_unit_wait_for_milk :string(255)      
#  duration_wait_for_meat      :integer          
#  duration_wait_for_milk      :integer          
#  event_id                    :integer          
#  frequency                   :integer          default(1), not null
#  id                          :integer          not null, primary key
#  lock_version                :integer          default(0), not null
#  name                        :string(255)      
#  per_animal_unit             :string(255)      
#  per_duration_time_unit      :string(255)      
#  per_frequency_time_unit     :string(255)      
#  prescription_id             :integer          
#  quantity                    :decimal(19, 4)   default(0.0), not null
#  quantity_unit_id            :integer          
#  started_at                  :datetime         
#  stopped_at                  :datetime         
#  updated_at                  :datetime         not null
#  updater_id                  :integer          
#
require 'test_helper'

class AnimalTreatmentTest < ActiveSupport::TestCase

  # Replace this with your real tests.'
  test "the truth" do
    assert true
  end

end
