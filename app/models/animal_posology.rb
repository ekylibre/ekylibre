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
#  animal_race_id                 :integer          
#  created_at                     :datetime         not null
#  creator_id                     :integer          
#  currative_quantity             :decimal(19, 4)   default(0.0), not null
#  description                    :string(255)      
#  disease_id                     :integer          
#  drug_admission_way             :string(255)      
#  drug_id                        :integer          
#  id                             :integer          not null, primary key
#  lock_version                   :integer          default(0), not null
#  preventive_quantity            :decimal(19, 4)   default(0.0), not null
#  product_category_id            :integer          
#  product_category_waiting_delay :string(255)      
#  quantity_delay                 :string(255)      
#  quantity_interval              :string(255)      
#  quantity_unit_id               :integer          
#  updated_at                     :datetime         not null
#  updater_id                     :integer          
#


class AnimalPosology < CompanyRecord
  attr_accessible :name, :comment, :animal_race_id,:drug_id, :disease_id, :quantity_unit_id, :product_category, :prescripted, :preventive_quantity, :currative_quantity, :quantity_interval, :quantity_delay, :product_category_waiting_delay
  belongs_to :animal_race, :class_name=>"AnimalRace"
  belongs_to :drug, :class_name=>"AnimalDrug"
  belongs_to :disease, :class_name=>"AnimalDisease"
  belongs_to :quantity_unit, :class_name=>"Unit"
  belongs_to :product_category, :class_name=>"ProductCategory"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :currative_quantity, :preventive_quantity, :allow_nil => true
  validates_length_of :description, :drug_admission_way, :product_category_waiting_delay, :quantity_delay, :quantity_interval, :allow_nil => true, :maximum => 255
  validates_presence_of :currative_quantity, :preventive_quantity
  #]VALIDATORS]

end
