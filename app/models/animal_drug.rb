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
# == Table: animal_drugs
#
#  comment      :text             
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  nature_id    :integer          not null
#  prescripted  :boolean          default(TRUE)
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class AnimalDrug < CompanyRecord
  attr_accessible :name, :comment, :nature_id, :prescripted, :posologies_attributes
  belongs_to :nature, :class_name => "AnimalDrugNature"
  has_many :posologies, :class_name => "AnimalPosology", :foreign_key => :drug_id
  has_many :treatments, :class_name => "AnimalTreatment", :foreign_key => :drug_id
  has_many :animal_races, :through => :posologies
  has_many :diseases, :through => :posologies
  has_many :product_categories, :through => :posologies
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_presence_of :name, :nature
  #]VALIDATORS]
  validates_uniqueness_of :name

  accepts_nested_attributes_for :posologies,    :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :animal_races,    :reject_if => :all_blank, :allow_destroy => false
  accepts_nested_attributes_for :diseases,    :reject_if => :all_blank, :allow_destroy => false
  accepts_nested_attributes_for :product_categories,    :reject_if => :all_blank, :allow_destroy => false
end
