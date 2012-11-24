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
# == Table: animal_cares
#
#  animal_group_id   :integer
#  animal_id         :integer
#  comment           :text
#  created_at        :datetime         not null
#  creator_id        :integer
#  description       :text
#  end_on            :datetime
#  entity_id         :integer
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  name              :string(255)      not null
#  nature_id         :integer          not null
#  quantity_per_care :decimal(, )
#  start_on          :datetime
#  updated_at        :datetime         not null
#  updater_id        :integer
#


class AnimalCare < CompanyRecord
  belongs_to :nature, :class_name => "AnimalCareNature"
  belongs_to :animal, :class_name => "Animal"
  belongs_to :animal_group, :class_name => "AnimalGroup"
  belongs_to :entity, :class_name => "Entity"
  has_and_belongs_to_many :drugs, :class_name => "Drug"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :quantity_per_care, :allow_nil => true
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_presence_of :name, :nature
  #]VALIDATORS]
end
