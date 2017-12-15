# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: intervention_template_product_parameters
#
#  activity_id               :integer
#  created_at                :datetime         not null
#  id                        :integer          not null, primary key
#  intervention_template_id  :integer
#  procedure                 :jsonb
#  product_nature_id         :integer
#  product_nature_variant_id :integer
#  quantity                  :integer
#  type                      :string
#  unit                      :string
#  updated_at                :datetime         not null
#
class InterventionTemplate::ProductParameter < ActiveRecord::Base
  # Relation
  belongs_to :intervention_template, class_name: 'InterventionTemplate', foreign_key: :intervention_template_id
  belongs_to :product_nature, class_name: 'ProductNature', foreign_key: :product_nature_id
  belongs_to :product_nature_variant, class_name: 'ProductNatureVariant', foreign_key: :product_nature_variant_id

  # Validation
  validates :quantity, presence: true
  validates :product_nature, presence: true, unless: :product_nature_variant_id?
  validates :product_nature_variant, presence: true, unless: :product_nature_id?

  attr_accessor :product_name

  # Need to access product_name in js
  def attributes
    super.merge(product_name: '')
  end
end
