# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
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
# == Table: animal_treatment_uses



class AnimalTreatmentUse < CompanyRecord
  attr_readonly :event_id, :drug_admission_path, :treatment_id, :per_animal_unit, :quantity_unit_id, :drug_allowed_id, :quantity
  attr_accessible :event_id, :drug_admission_path, :per_animal_unit, :quantity_unit_id, :drug_allowed_id, :quantity
  enumerize :drug_admission_path, :in => [:oral, :ima, :imu, :iu, :iv], default: :oral
  enumerize :per_animal_unit, :in => [:per_animal, :per_kg], default: :per_animal
  belongs_to :event, :class_name => "AnimalEvent"
  belongs_to :treatment, :class_name => "AnimalTreatment"
  belongs_to :quantity_unit, :class_name => "Unit"
  belongs_to :drug_allowed, :class_name => "Drug", :conditions => {:prescripted => false }
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :quantity, :allow_nil => true
  validates_length_of :drug_admission_path, :name, :per_animal_unit, :allow_nil => true, :maximum => 255
  validates_presence_of :quantity
  #]VALIDATORS]
end
