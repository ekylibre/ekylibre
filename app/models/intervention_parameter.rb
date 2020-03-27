# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
#  allowed_entry_factor     :interval
#  allowed_harvest_factor   :interval
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
#  usage_id                 :string
#  variant_id               :integer
#  variety                  :string
#  working_zone             :geometry({:srid=>4326, :type=>"multi_polygon"})
#
class InterventionParameter < Ekylibre::Record::Base
  attr_readonly :reference_name
  belongs_to :group, class_name: 'InterventionGroupParameter'
  belongs_to :parent, class_name: 'InterventionGroupParameter', foreign_key: :group_id, inverse_of: :children
  belongs_to :intervention, inverse_of: :parameters
  belongs_to :usage, class_name: 'RegisteredPhytosanitaryUsage'

  has_interval :allowed_entry_factor, :allowed_harvest_factor

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :allowed_entry_factor, :allowed_harvest_factor, :batch_number, :currency, :identification_number, :new_name, :quantity_handler, :quantity_indicator_name, :quantity_unit_name, :variety, length: { maximum: 500 }, allow_blank: true
  validates :dead, inclusion: { in: [true, false] }
  validates :quantity_population, :quantity_value, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :reference_name, presence: true, length: { maximum: 500 }
  validates :unit_pretax_stock_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :intervention, presence: true
  # ]VALIDATORS]
  validates :position, presence: true

  scope :of_activity, lambda { |activity|
    where(intervention_id: InterventionTarget.select(:intervention_id).of_activity(activity))
  }
  scope :of_activity_production, lambda { |production|
    where(intervention_id: InterventionTarget.select(:intervention_id).of_activity_production(production))
  }
  scope :of_generic_role, lambda { |role|
    role = role.to_s
    unless %w[doer input output target tool].include?(role)
      raise ArgumentError, "Invalid role: #{role}"
    end
    where(type: "Intervention#{role.camelize}")
  }
  scope :of_generic_roles, lambda { |roles|
    roles.collect! do |role|
      role = role.to_s
      unless %w[doer input output target tool].include?(role)
        raise ArgumentError, "Invalid role: #{role}"
      end
      "Intervention#{role.camelize}"
    end

    where(type: roles)
  }

  scope :of_actor, ->(actor) { where(product_id: actor.id) }

  scope :of_variety, lambda { |intervention_id, variety|
    product_nature_variant_ids = ProductNatureVariant.where(variety: variety).map(&:id)
    where('intervention_id = ? AND variant_id IN (?)', intervention_id, product_nature_variant_ids).to_a
  }

  before_validation do
    self.intervention ||= group.intervention if group
    if reference
      self.position = reference.position
    elsif position.blank?
      precision = 10**8
      now = Time.zone.now
      self.position = (precision * now.to_f).round - (precision * now.to_i)
    end
    true
  end

  before_save do
    self.intervention_id ||= self.intervention.id
  end

  def self.role
    @role ||= name.gsub(/^Intervention/, '').underscore.to_sym
  end

  def role
    self.class.role
  end

  # Returns a Procedo::Parameter corresponding to its reference_name
  # in the current procedure
  def reference
    if @reference.blank? && intervention
      @reference = procedure.find(reference_name)
    end
    @reference
  end

  def runnable?
    true
  end

  def cost_amount_computation(nature: nil, natures: {})
    AmountComputation.none
  end

  def cost(nature: nil, natures: {})
    cost_amount_computation(nature: nature, natures: natures).amount
  end

  def earn_amount_computation
    AmountComputation.none
  end

  def earn
    earn_amount_computation.amount
  end

  def self.order_by_product_name
    joins(:product).order('products.name')
  end

  def self.compare_with_planned
    result = true
    associations = { InterventionDoer: :doers, InterventionTool: :tools, InterventionInput: :inputs }

    return true if self.all.empty?

    param = self.first
    if param.intervention.record?
      intervention = param.intervention.reload
      request_intervention = intervention.request_intervention.reload
    else
      request_intervention = param.intervention.reload
      intervention = request_intervention.record_interventions.first.reload
    end

    association = associations[param.type.to_sym]
    self_parameters = intervention.send(association)
    request_parameters = request_intervention.send(association)

    return false if (self_parameters.empty? && request_parameters.any?) || (self_parameters.any? && request_parameters.empty?)

    unless self_parameters.empty? && request_parameters.empty?
      return false if self_parameters.group_by(&:product_id).count != request_parameters.group_by(&:product_id).count

      request_parameters.group_by(&:product_id).each do |product_id, request_param|
        self_param = intervention.product_parameters.where(product_id: product_id)

        return false if self_param.empty?

        if self_param.first.input?
          self_quantity = self_param.map(&:quantity_population).compact.sum
          request_quantity = request_param.map(&:quantity_population).compact.sum

          percent = Intervention::PLANNED_REALISED_ACCEPTED_GAP[request_param.first.type.underscore.to_sym] || 1.2
          intervals = (request_quantity / percent..request_quantity * percent)

          return false unless intervals.include?(self_quantity)
        else
          rq_duration = 0
          request_param.each { |param| rq_duration += calculate_cost_amount_computation(param).quantity }

          self_duration = 0
          self_param.each { |param| self_duration += calculate_cost_amount_computation(param).quantity }

          percent = Intervention::PLANNED_REALISED_ACCEPTED_GAP[request_param.first.type.underscore.to_sym] || 1.2
          intervals = (rq_duration / percent..rq_duration * percent)

          return false unless intervals.include?(self_duration)
        end
      end
    end
    result
  end

  def self.calculate_cost_amount_computation(product_parameter)
    if product_parameter.product.is_a?(Worker)
      computation = product_parameter.cost_amount_computation
    elsif product_parameter.product.try(:tractor?) && product_parameter.participation.present?
      computation = product_parameter.cost_amount_computation(natures: %i[travel intervention])
    else
      computation = product_parameter.cost_amount_computation(natures: %i[intervention])
    end
    computation
  end
end
