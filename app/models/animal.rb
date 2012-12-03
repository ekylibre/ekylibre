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
# == Table: animals
#
#  born_on               :date
#  ceded_on              :date
#  comment               :text
#  created_at            :datetime         not null
#  creator_id            :integer
#  description           :text
#  father_id             :integer
#  group_id              :integer          not null
#  id                    :integer          not null, primary key
#  identification_number :string(255)      not null
#  income_on             :date
#  lock_version          :integer          default(0), not null
#  mother_id             :integer
#  name                  :string(255)      not null
#  outgone_on            :date
#  picture_content_type  :string(255)
#  picture_file_name     :string(255)
#  picture_file_size     :integer
#  picture_updated_at    :datetime
#  purchased_on          :date
#  race_id               :integer
#  sex                   :string(16)       default("male"), not null
#  updated_at            :datetime         not null
#  updater_id            :integer
#


class Animal < CompanyRecord
  SEXES = ["male", "female"]
  attr_accessible :born_on, :ceded_on, :comment, :description, :father_id, :mother_id, :group_id, :identification_number, :income_on, :name, :outgone_on, :picture, :purchased_on, :race_id, :sex
  has_attached_file :picture, :styles => { :medium => "300x300>", :thumb => "100x100>" }
  belongs_to :group, :class_name => "AnimalGroup"
  belongs_to :race, :class_name => "AnimalRace"
  belongs_to :father, :class_name => "Animal"
  belongs_to :mother, :class_name => "Animal"
  has_many :cares, :class_name => "AnimalCare", :foreign_key => :animal_id
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :picture_file_size, :allow_nil => true, :only_integer => true
  validates_length_of :sex, :allow_nil => true, :maximum => 16
  validates_length_of :identification_number, :name, :picture_content_type, :picture_file_name, :allow_nil => true, :maximum => 255
  validates_presence_of :group, :identification_number, :name, :sex
  #]VALIDATORS]
  validates_uniqueness_of :name, :identification_number
  validates_inclusion_of :sex, :in => SEXES
end
