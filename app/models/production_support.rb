# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2013 Brice Texier, David Joulin
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
#  irrigated     :boolean          not null
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
  has_many :markers, class_name: "ProductionSupportMarker", foreign_key: :support_id, inverse_of: :support
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_inclusion_of :exclusive, :irrigated, in: [true, false]
  validates_presence_of :production, :storage
  #]VALIDATORS]
  validates_uniqueness_of :storage_id, scope: :production_id

  delegate :net_surface_area, :shape_area, to: :storage, prefix: true
  delegate :name, to: :production, prefix: true
  delegate :name, :shape, :shape_as_ewkt, to: :storage

  accepts_nested_attributes_for :markers, :reject_if => :all_blank, :allow_destroy => true

  scope :of_campaign, lambda { |*campaigns|
    campaigns.flatten!
    for campaign in campaigns
      raise ArgumentError.new("Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}") unless campaign.is_a?(Campaign)
    end
    joins(:production).merge(Production.of_campaign(campaigns))
  }

  # Measure a product for a given indicator
  def is_measured!(indicator, value, options = {})
    unless indicator.is_a?(Nomen::Item) or indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    if value.nil?
      raise ArgumentError, "Value must be given"
    end
    datum = self.markers.build(indicator_name: indicator.name, started_at: (options[:at] || Time.now))
    datum.value = value
    datum.save!
    return datum
  end

  # # Return the indicator datum
  # def indicator(indicator, options = {})
  #   ActiveSupport::Deprecation.warn("Product#indicator method is deprecated. Please use Product#indicate instead")
  #   return indicate(indicator, options)
  # end

  # Return the indicator datum
  def indicator_datum(indicator, options = {})
    unless indicator.is_a?(Nomen::Item) or indicator = Nomen::Indicators[indicator]
      raise ArgumentError, "Unknown indicator #{indicator.inspect}. Expecting one of them: #{Nomen::Indicators.all.sort.to_sentence}."
    end
    started_at = options[:at] || Time.now
    return self.markers.where(indicator_name: indicator.name).where("started_at <= ?", started_at).reorder(started_at: :desc).first
  end


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
      for input in intervention.casts.of_role('soil_enrichment-input')
        m = (input.actor ? input.actor.net_weight(input).to_d(:kilogram) : 0.0)
        n = (input.actor ? input.actor.nitrogen_concentration(input).to_d(:unity) : 0.0)
        balance <<  m * n
      end
    end
    # if net_surface_area, make the division
    if surface_area = self.storage_net_surface_area(self.started_at)
      nitrogen_unity_per_hectare = (balance.compact.sum / surface_area.to_d(:hectare))
    end
    return nitrogen_unity_per_hectare
  end

  def provisionnal_nitrogen_input
    balance = []
    markers = self.markers.where(aim: 'perfect', indicator_name: 'provisionnal_nitrogen_input')
    if markers.count > 0
      for marker in markers
        balance << marker.measure_value_value
      end
      return balance.compact.sum
    else
      return 0
    end
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

  # return the started_at attribute of the intervention of nature sowing if exist and if it's a vegetal production
  def sowed_at
    if sowing_intervention = self.interventions.real.of_nature(:sowing).first
      return sowing_intervention.started_at
    end
    return nil
  end

  # return the started_at attribute of the intervention of nature harvesting if exist and if it's a vegetal production
  def harvest_at
    if harvest_intervention = self.interventions.real.of_nature(:harvest).first
      return harvest_intervention.started_at
    end
    return nil
  end

  def grains_yield(unit = :quintal)
    if self.interventions.real.of_nature(:harvest).count > 1
      total_yield = []
      for harvest in self.interventions.real.of_nature(:harvest)
        for input in harvest.casts.of_role('harvest-output').where(reference_name: "grains")
          q = (input.actor ? input.actor.net_weight(input).to_d(unit) : 0.0)
          total_yield << q
        end
      end
      if self.storage.net_surface_area
        return ((total_yield.compact.sum) / (net_surface_area.to_d(:hectare)))
      end
    end
    return nil
  end

end


