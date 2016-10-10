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
# == Table: intervention_parameters
#
#  assembly_id              :integer
#  component_id             :integer
#  created_at               :datetime         not null
#  creator_id               :integer
#  currency                 :string
#  event_participation_id   :integer
#  group_id                 :integer
#  id                       :integer          not null, primary key
#  intervention_id          :integer          not null
#  lock_version             :integer          default(0), not null
#  new_container_id         :integer
#  new_group_id             :integer
#  new_name                 :string
#  new_variant_id           :integer
#  outcoming_product_id     :integer
#  position                 :integer          not null
#  product_id               :integer
#  quantity_handler         :string
#  quantity_indicator_name  :string
#  quantity_population      :decimal(19, 4)
#  quantity_unit_name       :string
#  quantity_value           :decimal(19, 4)
#  reference_name           :string           not null
#  type                     :string
#  unit_pretax_stock_amount :decimal(19, 4)   default(0.0), not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#  variant_id               :integer
#  working_zone             :geometry({:srid=>4326, :type=>"multi_polygon"})
#

# This class is used for all intervenants that make the interventions. It
# gathers tools and doers.
class InterventionAgent < InterventionProductParameter
  belongs_to :intervention, inverse_of: :agents
  validates :product, presence: true

  delegate :working_duration, to: :intervention

  def cost_amount_computation
    return InterventionParameter::AmountComputation.failed unless product
    options = {
      catalog_usage: :cost,
      quantity: working_duration.to_d / 3600,
      unit_name: Nomen::Unit.find(:hour).human_name
    }
    options[:catalog_item] = product.default_catalog_item(options[:catalog_usage])
    InterventionParameter::AmountComputation.quantity(:catalog, options)
  end
end
