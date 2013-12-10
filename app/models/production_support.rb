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
# == Table: production_supports
#
#  created_at    :datetime         not null
#  creator_id    :integer
#  exclusive     :boolean          not null
#  id            :integer          not null, primary key
#  lock_version  :integer          default(0), not null
#  production_id :integer          not null
#  started_at    :datetime
#  stopped_at    :datetime
#  storage_id    :integer          not null
#  updated_at    :datetime         not null
#  updater_id    :integer
#
class ProductionSupport < Ekylibre::Record::Base
  belongs_to :storage, class_name: "Product", inverse_of: :supports
  belongs_to :production, inverse_of: :supports
  has_many :interventions
  has_many :marker_data, class_name: "ProductionSupportMarker", foreign_key: :support_id, inverse_of: :support
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_inclusion_of :exclusive, in: [true, false]
  validates_presence_of :production, :storage
  #]VALIDATORS]
  validates_uniqueness_of :storage_id, scope: :production_id

  delegate :net_surface_area, :shape_area, to: :storage, prefix: true
  delegate :name, :shape, :shape_as_ewkt, to: :storage

  accepts_nested_attributes_for :marker_data, :reject_if => :all_blank, :allow_destroy => true

  def cost(role=:input)
    cost = []
    for intervention in self.interventions
      cost << intervention.cost(role)
    end
    return cost.compact.sum
  end

  def nitrogen_balance
    balance = []
    # get all intervention of nature 'soil_enrichment' and sum all nitrogen unity spreaded
    # m = net_weight of the input at intervention time
    # n = nitrogen concentration (in %) of the input at intervention time
    for intervention in self.interventions.real.of_nature(:soil_enrichment)
      for input in intervention.casts.of_role(:'soil_enrichment-input')
        m = input.actor.net_weight.convert(:kilogram).to_s.to_f if !input.actor.net_weight.nil?
        m ||= 0.0
        n = input.actor.nitrogen_concentration.to_s.to_f if !input.actor.nitrogen_concentration.nil?
        n ||= 0.0
        balance << ( m * ( n / 100 ))
      end
    end
    # if net_surface_area, make the division
    if self.storage_net_surface_area(self.started_at).to_s.to_f > 0.0
      nitrogen_unity_per_hectare = (balance.compact.sum / (self.storage_net_surface_area(self.started_at).convert(:hectare).to_s.to_f))
    end
    return nitrogen_unity_per_hectare
  end

  def tool_cost
    if self.storage_net_surface_area(self.started_at).to_s.to_f > 0.0
      self.cost(:tool)/(self.storage_net_surface_area(self.started_at).convert(:hectare).to_s.to_f)
    end
  end

  def input_cost
    if self.storage_net_surface_area(self.started_at).to_s.to_f > 0.0
      self.cost(:input)/(self.storage_net_surface_area(self.started_at).convert(:hectare).to_s.to_f)
    end
  end

  def time_cost
    if self.storage_net_surface_area(self.started_at).to_s.to_f > 0.0
      self.cost(:doer)/(self.storage_net_surface_area(self.started_at).convert(:hectare).to_s.to_f)
    end
  end

end


