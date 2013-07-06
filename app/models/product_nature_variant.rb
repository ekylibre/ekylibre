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
# == Table: product_nature_variants
#
#  active                  :boolean          not null
#  commercial_description  :text
#  commercial_name         :string(255)      not null
#  contour                 :string(255)
#  created_at              :datetime         not null
#  creator_id              :integer
#  horizontal_rotation     :integer          default(0), not null
#  id                      :integer          not null, primary key
#  lock_version            :integer          default(0), not null
#  name                    :string(255)
#  nature_id               :integer          not null
#  nature_name             :string(255)      not null
#  number                  :string(255)
#  purchase_indicator      :decimal(19, 4)
#  purchase_indicator_unit :string(255)
#  sale_indicator          :decimal(19, 4)
#  sale_indicator_unit     :string(255)
#  updated_at              :datetime         not null
#  updater_id              :integer
#  usage_indicator         :decimal(19, 4)
#  usage_indicator_unit    :string(255)
#
class ProductNatureVariant < Ekylibre::Record::Base
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :horizontal_rotation, :allow_nil => true, :only_integer => true
  validates_numericality_of :purchase_indicator, :sale_indicator, :usage_indicator, :allow_nil => true
  validates_length_of :commercial_name, :contour, :name, :nature_name, :number, :purchase_indicator_unit, :sale_indicator_unit, :usage_indicator_unit, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :in => [true, false]
  validates_presence_of :commercial_name, :horizontal_rotation, :nature_name
  #]VALIDATORS]
end
