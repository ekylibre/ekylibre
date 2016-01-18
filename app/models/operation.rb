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
# == Table: operations
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  duration        :integer
#  id              :integer          not null, primary key
#  intervention_id :integer          not null
#  lock_version    :integer          default(0), not null
#  reference_name  :string           not null
#  started_at      :datetime         not null
#  stopped_at      :datetime         not null
#  updated_at      :datetime         not null
#  updater_id      :integer
#

class TaskPerformingError < StandardError
end

class Operation < Ekylibre::Record::Base
  include PeriodicCalculable
  belongs_to :intervention, inverse_of: :operations
  has_many :product_enjoyments,        dependent: :destroy
  has_many :product_junctions,         dependent: :destroy
  has_many :product_linkages,          dependent: :destroy
  has_many :product_localizations,     dependent: :destroy
  has_many :product_memberships,       dependent: :destroy
  has_many :product_ownerships,        dependent: :destroy
  has_many :product_phases,            dependent: :destroy
  has_many :product_reading_tasks,     dependent: :destroy

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :duration, allow_nil: true, only_integer: true
  validates_presence_of :intervention, :reference_name, :started_at, :stopped_at
  # ]VALIDATORS]

  delegate :reference, to: :intervention, prefix: true
  delegate :casts, to: :intervention

  scope :unvalidateds, -> { where(confirmed: false) }

  scope :of_campaign, lambda { |*campaigns|
    list = campaigns.flatten.compact.map do |campaign|
      unless campaign.is_a?(Campaign)
        fail ArgumentError, "Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}"
      end
      campaign
    end
    joins(intervention: :production).merge(Production.of_campaign(list))
  }

  scope :of_activities, lambda { |*activities|
    activities.flatten!
    for activity in activities
      fail ArgumentError.new("Expected Activity, got #{activity.class.name}:#{activity.inspect}") unless activity.is_a?(Activity)
    end
    joins(intervention: :production).merge(Production.of_activities(activities))
  }

  scope :with_cast, lambda { |role, object|
    joins(:intervention).merge(Intervention.with_cast(role, object))
  }

  scope :with_generic_cast, lambda { |role, object|
    joins(:intervention).merge(Intervention.with_generic_cast(role, object))
  }

  calculable period: :month, at: :started_at, column: :duration

  before_validation(on: :create) do
    self.duration = (stopped_at - started_at).to_i if started_at && stopped_at
  end

  validate do
    if started_at && stopped_at
      if stopped_at < started_at
        errors.add(:stopped_at, :posterior, to: started_at.l)
      end
    end
  end

  # before_update :cancel_all!
  # after_save :perform_all!
  # after_destroy :cancel_all!

  # Perform all tasks as defined in reference
  def perform_all!
    for task in reference.tasks.values
      perform(task)
    end
  end

  # def cancel_all!
  #   for task in self.reference.tasks.values
  #     cancel(task)
  #   end
  # end

  def reference
    intervention_reference.operations[reference_name]
  end

  def description
    reference ? reference.human_expressions.to_sentence : '???'
  end

  private

  def task_actors(task)
    task.parameters.inject({}) do |hash, pair|
      parameter = pair.second
      hash[pair.first] = if parameter.is_a?(Procedo::Variable)
                           casts.find_by!(reference_name: parameter.name.to_s)
                         elsif parameter.is_a?(Procedo::Indicator)
                           # [self.casts.find_by!(reference_name: parameter.stakeholder.name.to_s), parameter]
                           Indicatus.new(parameter, self)
                         else
                           fail StandardError, "Don't known how to find a #{parameter.class.name} for #{pair.first}"
                         end
      hash
    end
  end

  def perform(task)
    send("perform_#{task.action.type}", task, task_actors(task))
  rescue Exception => e
    raise TaskPerformingError, "Cannot perform #{task.action.type} (#{task.expression}) with #{task_actors(task).inspect}.\n#{e.message}.\n" + e.backtrace.join("\n")
  end

  # def cancel(task)
  #   method_name = "cancel_#{task.action.type}"
  #   if respond_to?(method_name)
  #     send(method_name, task_actors(task))
  #   end
  # end

  # == Localizations

  def perform_direct_movement(_reference, params)
    product_localizations.create!(started_at: started_at, nature: :interior, product: params[:product].actor, container: params[:localizable].actor.localizations.at(started_at).first.container)
  end

  def perform_direct_entering(_reference, params)
    product_localizations.create!(started_at: started_at, nature: :interior, product: params[:product].actor, container: params[:localizable].actor)
  end

  def perform_movement(_reference, params)
    product_localizations.create!(started_at: started_at, nature: :transfer, product: params[:product].actor)
    if localization = params[:localizable].actor.localizations.at(stopped_at).first
      while localization && localization.container.nil?
        break unless localization = localization.previous
      end
    end
    container = localization.container if localization
    container ||= params[:localizable].actor.default_storage
    # @ todo remove
    product_localizations.create!(started_at: stopped_at, nature: :interior, product: params[:product].actor, container: container)
  end

  def perform_entering(_reference, params)
    product_localizations.create!(started_at: started_at, nature: :transfer, product: params[:product].actor)
    product_localizations.create!(started_at: stopped_at, nature: :interior, product: params[:product].actor, container: params[:localizable].actor)
  end

  def perform_home_coming(_reference, params)
    product_localizations.create!(started_at: started_at, nature: :transfer, product: params[:product].actor)
    product_localizations.create!(started_at: stopped_at, nature: :interior, product: params[:product].actor, container: params[:product].actor.default_storage)
  end

  def perform_given_home_coming(_reference, params)
    product_localizations.create!(started_at: started_at, nature: :transfer, product: params[:product].actor)
    product_localizations.create!(started_at: stopped_at, nature: :interior, product: params[:product].actor, container: params[:localizable].actor.default_storage)
  end

  def perform_out_going(_reference, params)
    product_localizations.create!(started_at: started_at, nature: :transfer, product: params[:product].actor)
    product_localizations.create!(started_at: stopped_at, nature: :exterior, product: params[:product].actor)
  end

  # == Births

  def perform_creation(_reference, params)
    produced = params[:product].actor
    junction = product_junctions.create!(
      nature: :production,
      started_at: started_at,
      stopped_at: stopped_at,
      ways_attributes: [
        { role: :producer, product: params[:producer].actor },
        { role: :produced, product: produced }
      ]
    )
    produced.read_whole_indicators_from!(params[:product], at: stopped_at, force: true, originator: junction)
  end

  def perform_division(_reference, params)
    reduced = params[:producer].actor
    separated = params[:product].actor
    junction = product_junctions.create!(
      nature: :division,
      started_at: started_at,
      stopped_at: stopped_at,
      ways_attributes: [
        { role: :reduced, product: reduced },
        { role: :separated, product: separated }
      ]
    )

    # Duplicate individual indicator data
    separated.copy_readings_of!(reduced, at: stopped_at, taken_at: started_at, originator: junction)

    # Impact on following readings
    reduced.substract_and_read(params[:product], at: stopped_at, taken_at: started_at, originator: junction)
  end

  # == Deaths

  def perform_death(_reference, params)
    product_junctions.create!(
      nature: :death,
      started_at: started_at,
      stopped_at: stopped_at,
      ways_attributes: [{ role: :dead, product: params[:product].actor }]
    )
  end

  def perform_consumption(_reference, params)
    product_junctions.create!(
      nature: :consumption,
      started_at: started_at,
      stopped_at: stopped_at,
      ways_attributes: [
        { role: :consumer, product: params[:absorber].actor },
        { role: :consumed, product: params[:product].actor }
      ]
    )
  end

  def perform_merging(_reference, params)
    absorber = params[:absorber].actor
    absorbed = params[:product].actor
    junction = product_junctions.create!(
      nature: :merging,
      started_at: started_at,
      stopped_at: stopped_at,
      ways_attributes: [
        { role: :absorber, product: absorber },
        { role: :absorbed, product: absorbed }
      ]
    )
    # Duplicate individual indicator data
    absorbed.copy_readings_of!(absorber, at: stopped_at, taken_at: started_at, originator: junction)

    # Add whole indicator data
    absorbed.add_and_read(params[:product], at: stopped_at, taken_at: started_at, originator: junction)
  end

  # == Phases

  def perform_variant_cast(_reference, params)
    product_phases.create!(
      started_at: stopped_at,
      product: params[:product].actor,
      variant: params[:variant].variant
    )
  end

  def perform_nature_cast(_reference, params)
    product_phases.create!(
      started_at: stopped_at,
      product: params[:product].actor,
      variant: params[:nature].variant.nature
    )
  end

  # == Mixing

  def perform_mixing(_reference, params)
    produced = params[:product].actor
    ways = [{ role: :produced, product: produced }]
    [:first_producer, :second_producer, :third_producer, :fourth_producer,
     :fifth_producer].each do |role|
      ways << { role: :mixed, product: params[role].actor } if params[role]
    end
    junction = product_junctions.create!(
      nature: :mixing,
      started_at: started_at,
      stopped_at: stopped_at,
      ways_attributes: ways
    )
    produced.read_whole_indicators_from!(params[:product], at: stopped_at, force: true, originator: junction)
  end

  def perform_triple_mixing(reference, params)
    perform_mixing(reference, params)
  end

  def perform_quadruple_mixing(reference, params)
    perform_mixing(reference, params)
  end

  def perform_quintuple_mixing(reference, params)
    perform_mixing(reference, params)
  end

  # == Linkages

  def perform_attachment(_reference, params)
    product_linkages.create!(started_at: stopped_at, point: params[:point].actor, carrier: params[:carrier].actor, carried: params[:carried].actor, nature: 'occupied')
  end

  def perform_detachment(_reference, params)
    if linkage = params[:carrier].actor.linkages.at(started_at).find_by(carried_id: params[:carried].actor.id)
      product_linkages.create!(started_at: stopped_at, carrier: params[:carrier].actor, point: linkage.point, nature: 'available')
    end
  end

  def perform_simple_attachment(_reference, params)
    product_linkages.create!(started_at: stopped_at, point: params[:carrier].actor.linkage_points.first, carrier: params[:carrier].actor, carried: params[:carried].actor, nature: 'occupied')
  end

  def perform_simple_detachment(_reference, params)
    product_linkages.create!(started_at: stopped_at, carrier: params[:carrier].actor, point: params[:point].actor, nature: 'available')
  end

  # == Memberships

  def perform_group_inclusion(_reference, params)
    product_memberships.create!(started_at: stopped_at, member: params[:member].actor, group: params[:group].actor, nature: 'interior')
  end

  def perform_group_exclusion(_reference, params)
    product_memberships.create!(started_at: stopped_at, member: params[:member].actor, group: params[:group].actor, nature: 'exterior')
  end

  # == Ownerships

  def perform_ownership_loss(_reference, params)
    product_ownerships.create!(started_at: stopped_at, nature: :unknown, product: params[:product].actor)
  end

  def perform_ownership_change(_reference, params)
    product_ownerships.create!(started_at: stopped_at, product: params[:product].actor, owner: params[:owner].actor)
  end

  # == Browsings

  def perform_browsing(_reference, _params)
  end

  # == Measurements

  def perform_simple_reading_task(reference, params)
    do_reading_task(reference, params)
  end

  def perform_reading_task(reference, params)
    do_reading_task(reference, params, reporter: params[:reporter].actor)
  end

  def perform_assisted_reading_task(reference, params)
    do_reading_task(reference, params, reporter: params[:reporter].actor, tool: params[:tool].actor)
  end

  protected

  def do_reading_task(reference, params, attributes = {})
    indicatus = params[:indicator]
    value = nil
    reading_task = product_reading_tasks.build(attributes.merge(product: indicatus.actor, indicator_name: indicatus.name, started_at: stopped_at))
    if indicatus.value?
      unless value = indicatus.computed_value
        fail "Cannot measure #{indicatus.inspect}."
      end
    else
      if intervention.parameters.is_a?(Hash) && intervention.parameters[:readings].is_a?(Hash) && value = intervention.parameters[:readings][reference.uid]
        if indicatus.indicator.datatype == :measure
          value = value.is_a?(String) ? Measure.new(value) : value[:value].to_f.in(value[:unit])
        end
      end
      # Rails.logger.warn("Measure without value are not possible for now")
    end
    unless value
      fail "Need a value for #{reference.expression} (#{indicatus.inspect})."
    end
    reading_task.value = value
    reading_task.save!
  end
end
