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


class AnimalTreatment < CompanyRecord
  attr_readonly :event_id, :drug_admission_path, :treatment_id, :per_animal_unit, :quantity_unit_id, :drug_allowed_id, :quantity
  attr_accessible :event_id, :drug_admission_path, :per_animal_unit, :quantity_unit_id, :drug_allowed_id, :quantity
  enumerize :per_animal_unit, :in => [:per_animal, :per_kg], default: :per_animal
  enumerize :per_frequency_time_unit, :in => [:times_per_day, :times_per_week, :times_per_month], default: :times_per_day
  enumerize :per_duration_time_unit, :in => [:hours, :days, :weeks, :months], default: :days
  enumerize :duration_unit_wait_for_milk, :in => [:hours, :days], default: :days
  enumerize :duration_unit_wait_for_meat, :in => [:hours, :days], default: :days
  enumerize :drug_admission_path, :in => [:oral, :ima, :imu, :iu, :iv], default: :oral
  belongs_to :disease, :class_name => "AnimalDisease"
  belongs_to :drug, :class_name => "AnimalDrug"
  belongs_to :event, :class_name => "AnimalEvent"
  belongs_to :prescription, :class_name => "AnimalPrescription"
  has_many :treatment_uses, :class_name => "AnimalTreatmentUse", :foreign_key => :treatment_id
  has_many :events, :through => :treatment_uses
  belongs_to :quantity_unit, :class_name => "Unit"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :duration_wait_for_meat, :duration_wait_for_milk, :frequency, :allow_nil => true, :only_integer => true
  validates_numericality_of :duration, :quantity, :allow_nil => true
  validates_length_of :duration_unit_wait_for_meat, :duration_unit_wait_for_milk, :name, :per_animal_unit, :per_duration_time_unit, :per_frequency_time_unit, :allow_nil => true, :maximum => 255
  validates_presence_of :frequency, :quantity
  #]VALIDATORS]
end
