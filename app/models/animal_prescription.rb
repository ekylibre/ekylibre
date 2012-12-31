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
# == Table: prescriptions



class AnimalPrescription < CompanyRecord
  has_many :treatments, :class_name=>"AnimalTreatment", :foreign_key => :prescription_id
  belongs_to :prescriptor, :class_name=>"Entity"
  has_attached_file :picture, :styles => { :medium => "300x300>", :thumb => "100x100>" }
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :picture_file_size, :allow_nil => true, :only_integer => true
  validates_length_of :name, :picture_content_type, :picture_file_name, :prescription_number, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  validates_presence_of :prescriptor
end
