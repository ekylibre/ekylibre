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
#  created_at         :datetime         not null
#  creator_id         :integer          
#  disease_id         :integer          
#  drug_admission_way :string(255)      
#  drug_id            :integer          
#  event_id           :integer          
#  id                 :integer          not null, primary key
#  lock_version       :integer          default(0), not null
#  name               :string(255)      
#  prescription_id    :integer          
#  quantity           :decimal(19, 4)   default(0.0), not null
#  quantity_delay     :string(255)      
#  quantity_interval  :string(255)      
#  started_at         :datetime         
#  stopped_at         :datetime         
#  updated_at         :datetime         not null
#  updater_id         :integer          
#


class AnimalTreatment < CompanyRecord
  attr_accessible :quantity_delay, :quantity_interval, :event_id, :drug_admission_way, :quantity, :name, :prescription_id, :disease_id, :drug_id, :started_at
  enumerize :drug_admission_way, :in => [:oral, :ima, :imu, :iu, :iv], :default=> :oral
  belongs_to :disease, :class_name => "AnimalDisease"
  belongs_to :drug, :class_name => "AnimalDrug"
  belongs_to :event, :class_name => "AnimalEvent"
  belongs_to :prescription, :class_name => "AnimalPrescription"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :quantity, :allow_nil => true
  validates_length_of :drug_admission_way, :name, :quantity_delay, :quantity_interval, :allow_nil => true, :maximum => 255
  validates_presence_of :quantity
  #]VALIDATORS]
end
