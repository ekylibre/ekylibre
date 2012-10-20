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


class Animal < CompanyRecord
  belongs_to :animal_group
  belongs_to :company
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :sexe, :allow_nil => true, :maximum => 1
  validates_length_of :ident_number, :name, :allow_nil => true, :maximum => 255
  validates_presence_of :born_on, :company, :ident_number, :in_on, :name, :out_on, :purchased_on, :sexe
  #]VALIDATORS]
  attr_readonly :company_id
  validates_uniqueness_of :name, :ident_number
end
