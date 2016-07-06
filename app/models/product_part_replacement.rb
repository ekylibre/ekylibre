# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: product_part_replacements
#
#  component_id              :integer          not null
#  created_at                :datetime         not null
#  creator_id                :integer
#  following_id              :integer
#  id                        :integer          not null, primary key
#  intervention_parameter_id :integer          not null
#  lock_version              :integer          default(0), not null
#  product_id                :integer          not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#
class ProductPartReplacement < Ekylibre::Record::Base

	belongs_to :product, inverse_of: :product_part_replacement
	belongs_to :component, class_name: "ProductNatureVariantComponent"
	belongs_to :intervention_parameter
	has_one :intervention, through: :intervention_parameter
	belongs_to :following, class_name:'ProductPartReplacement'
	has_many :precedings, class_name:'ProductPartReplacement', foreign_key: 'following_id'

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_presence_of :component, :intervention_parameter, :product
  # ]VALIDATORS]
end
