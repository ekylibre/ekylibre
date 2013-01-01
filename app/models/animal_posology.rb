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
# == Table: animal_posologies
#
#  animal_race_nature_id       :integer          
#  created_at                  :datetime         not null
#  creator_id                  :integer          
#  description                 :string(255)      
#  disease_id                  :integer          
#  drug_admission_path         :string(255)      
#  drug_id                     :integer          
#  duration_unit_wait_for_meat :string(255)      
#  duration_unit_wait_for_milk :string(255)      
#  duration_wait_for_meat      :integer          
#  duration_wait_for_milk      :integer          
#  frequency                   :integer          default(1), not null
#  id                          :integer          not null, primary key
#  lock_version                :integer          default(0), not null
#  per_duration_time_unit      :string(255)      
#  per_frequency_time_unit     :string(255)      
#  quantity                    :decimal(19, 4)   default(0.0), not null
#  quantity_unit_id            :integer          
#  updated_at                  :datetime         not null
#  updater_id                  :integer          
#


class AnimalPosology < CompanyRecord
  belongs_to :animal_race_nature, :class_name=>"AnimalRaceNature"
  belongs_to :drug, :class_name=>"AnimalDrug"
  belongs_to :disease, :class_name=>"AnimalDisease"
  belongs_to :quantity_unit, :class_name=>"Unit"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :duration_wait_for_meat, :duration_wait_for_milk, :frequency, :allow_nil => true, :only_integer => true
  validates_numericality_of :quantity, :allow_nil => true
  validates_length_of :description, :drug_admission_path, :duration_unit_wait_for_meat, :duration_unit_wait_for_milk, :per_duration_time_unit, :per_frequency_time_unit, :allow_nil => true, :maximum => 255
  validates_presence_of :frequency, :quantity
  #]VALIDATORS]

end
