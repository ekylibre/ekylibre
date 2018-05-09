# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
#  batch_number             :string
#  component_id             :integer
#  created_at               :datetime         not null
#  creator_id               :integer
#  currency                 :string
#  dead                     :boolean          default(FALSE), not null
#  event_participation_id   :integer
#  group_id                 :integer
#  id                       :integer          not null, primary key
#  identification_number    :string
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
#  variety                  :string
#  working_zone             :geometry({:srid=>4326, :type=>"multi_polygon"})
#
class InterventionTarget < InterventionProductParameter
  belongs_to :intervention, inverse_of: :targets
  validates :product, presence: true
  scope :of_activity, ->(activity) { where(product_id: Product.where(activity_production_id: activity.productions.select(:id))) }
  scope :of_activities, ->(activities) { where(product_id: Product.where(activity_production_id: activities.map { |a| a.productions.select(:id) }.flatten.uniq)) }
  scope :of_activity_production, ->(activity_production) { where(product_id: Product.where(activity_production: activity_production)) }
  scope :of_interventions, ->(interventions) { where(intervention_id: interventions.map(&:id)) }

  def best_activity
    production = best_activity_production
    production ? production.activity : nil
  end

  def activity
    ActiveSupport::Deprecation.warn('InterventionTarget#activity is deprecated. Method will be removed in 3.0. Please use InterventionTarget#best_activity instead.')
    best_activity
  end

  def best_activity_production
    return nil unless product
    product.best_activity_production(at: intervention.started_at)
  end

  def activity_production
    ActiveSupport::Deprecation.warn('InterventionTarget#activity_production is deprecated. Method will be removed in 3.0. Please use InterventionTarget#best_activity_production instead.')
    best_activity_production
  end
end
