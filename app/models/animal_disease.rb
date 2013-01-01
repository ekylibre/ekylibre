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
# == Table: animal_diseases
#
#  code         :string(255)      
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#  zone         :string(255)      
#


class AnimalDisease < CompanyRecord
  has_many :posologies, :class_name => "AnimalPosology", :foreign_key => :disease_id
  has_many :diagnostics, :class_name => "AnimalDiagnostic", :foreign_key => :disease_id
  has_many :events, :class_name => "AnimalEvent", :through => :diagnostics
  has_many :treatments, :class_name => "AnimalTreatment", :foreign_key => :disease_id
  has_many :drugs, :class_name => "AnimalDrug", :through => :treatments
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :code, :name, :zone, :allow_nil => true, :maximum => 255
  validates_presence_of :name
  #]VALIDATORS]
end
