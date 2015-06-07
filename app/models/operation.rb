# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
  has_many :product_births,            dependent: :destroy
  has_many :product_consumptions,      dependent: :destroy
  has_many :product_creations,         dependent: :destroy
  has_many :product_deaths,            dependent: :destroy
  has_many :product_divisions,         dependent: :destroy
  has_many :product_enjoyments,        dependent: :destroy
  has_many :product_linkages,          dependent: :destroy
  has_many :product_localizations,     dependent: :destroy
  has_many :product_memberships,       dependent: :destroy
  has_many :product_mergings,          dependent: :destroy
  has_many :product_mixings,           dependent: :destroy
  has_many :product_ownerships,        dependent: :destroy
  has_many :product_phases,            dependent: :destroy
  has_many :product_quadruple_mixings, dependent: :destroy
  has_many :product_quintuple_mixings, dependent: :destroy
  has_many :product_reading_tasks,     dependent: :destroy
  has_many :product_triple_mixings,    dependent: :destroy

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :duration, allow_nil: true, only_integer: true
  validates_presence_of :intervention, :reference_name, :started_at, :stopped_at
  #]VALIDATORS]

  delegate :reference, to: :intervention, prefix: true
  delegate :casts, to: :intervention

  scope :unvalidateds, -> { where(confirmed: false) }

  scope :of_campaign, lambda { |*campaigns|
    list = campaigns.flatten.compact.map do |campaign|
      unless campaign.is_a?(Campaign)
        raise ArgumentError, "Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}"
      end
      campaign
    end
    joins(intervention: :production).merge(Production.of_campaign(list))
  }

  scope :of_activities, lambda { |*activities|
    activities.flatten!
    for activity in activities
      raise ArgumentError.new("Expected Activity, got #{activity.class.name}:#{activity.inspect}") unless activity.is_a?(Activity)
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
    if self.started_at and self.stopped_at
      self.duration = (self.stopped_at - self.started_at).to_i
    end
  end

  validate do
    if self.started_at and self.stopped_at
      if self.stopped_at < self.started_at
        errors.add(:stopped_at, :posterior, to: self.started_at.l)
      end
    end
  end

  # before_update :cancel_all!
  # after_save :perform_all!
  # after_destroy :cancel_all!

  # Perform all tasks as defined in reference
  def perform_all!
    for task in self.reference.tasks.values
      perform(task)
    end
  end

  # def cancel_all!
  #   for task in self.reference.tasks.values
  #     cancel(task)
  #   end
  # end

  def reference
    self.intervention_reference.operations[self.reference_name]
  end

  def description
    self.reference ? self.reference.human_expressions.to_sentence : "???"
  end

  private

  def task_actors(task)
    return task.parameters.inject({}) do |hash, pair|
      parameter = pair.second
      hash[pair.first] = if parameter.is_a?(Procedo::Variable)
                           self.casts.find_by!(reference_name: parameter.name.to_s)
                         elsif parameter.is_a?(Procedo::Indicator)
                           # [self.casts.find_by!(reference_name: parameter.stakeholder.name.to_s), parameter]
                           Indicatus.new(parameter, self)
                         else
                           raise StandardError, "Don't known how to find a #{parameter.class.name} for #{pair.first}"
                         end
      hash
    end
  end



  def perform(task)
    begin
      send("perform_#{task.action.type}", task, task_actors(task))
    rescue Exception => e
      raise TaskPerformingError, "Cannot perform #{task.action.type} (#{task.expression}) with #{task_actors(task).inspect}.\n#{e.message}.\n" + e.backtrace.join("\n")
    end
  end

  # def cancel(task)
  #   method_name = "cancel_#{task.action.type}"
  #   if respond_to?(method_name)
  #     send(method_name, task_actors(task))
  #   end
  # end


  # == Localizations

  def perform_direct_movement(reference, params)
    self.product_localizations.create!(started_at: self.started_at, nature: :interior, product: params[:product].actor, container: params[:localizable].actor.localizations.at(self.started_at).first.container)
  end

  def perform_direct_entering(reference, params)
    self.product_localizations.create!(started_at: self.started_at, nature: :interior, product: params[:product].actor, container: params[:localizable].actor)
  end

  def perform_movement(reference, params)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product: params[:product].actor)
    if localization = params[:localizable].actor.localizations.at(self.stopped_at).first
      while localization and localization.container.nil?
        break unless localization = localization.previous
      end
    end
    container = localization.container if localization
    container ||= params[:localizable].actor.default_storage
    # @ todo remove
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product: params[:product].actor, container: container)
  end

  def perform_entering(reference, params)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product: params[:product].actor)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product: params[:product].actor, container: params[:localizable].actor)
  end

  def perform_home_coming(reference, params)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product: params[:product].actor)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product: params[:product].actor, container: params[:product].actor.default_storage)
  end

  def perform_given_home_coming(reference, params)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product: params[:product].actor)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product: params[:product].actor, container: params[:localizable].actor.default_storage)
  end

  def perform_out_going(reference, params)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product: params[:product].actor)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :exterior, product: params[:product].actor)
  end

  # == Births

  def perform_creation(reference, params)
    # self.product_creations.create!(started_at: self.started_at, stopped_at: self.stopped_at, product: params[:product].actor, producer: params[:producer].actor)
    producer = params[:producer].actor
    attributes = {started_at: self.started_at, stopped_at: self.stopped_at, product_way_attributes: {road: params[:product].actor}, producer: producer}
    for indicator_name in producer.whole_indicators_list
      attributes[:product_way_attributes][indicator_name] = params[:product].send(indicator_name)
    end
    self.product_creations.create!(attributes)
  end

  def perform_division(reference, params)
    producer = params[:producer].actor
    attributes = {started_at: self.started_at, stopped_at: self.stopped_at, product_way_attributes: {road: params[:product].actor}, producer: producer}
    for indicator_name in producer.whole_indicators_list
      attributes[:product_way_attributes][indicator_name] = params[:product].send(indicator_name)
    end
    self.product_divisions.create!(attributes)
  end

  # == Deaths

  def perform_death(reference, params)
    self.product_deaths.create!(started_at: self.started_at, stopped_at: self.stopped_at, product: params[:product].actor)
  end

  def perform_consumption(reference, params)
    self.product_consumptions.create!(started_at: self.started_at, stopped_at: self.stopped_at, product: params[:product].actor, consumer: params[:absorber].actor)
  end

  def perform_merging(reference, params)
    self.product_mergings.create!(started_at: self.started_at, stopped_at: self.stopped_at, product: params[:product].actor, absorber: params[:absorber].actor)
  end

  # == Phases

  def perform_variant_cast(reference, params)
    self.product_phases.create!(started_at: self.stopped_at, product: params[:product].actor, variant: params[:variant].variant)
  end

  def perform_nature_cast(reference, params)
    self.product_phases.create!(started_at: self.stopped_at, product: params[:product].actor, variant: params[:nature].variant.nature)
  end


  # == Mixing

  def perform_mixing(reference, params)
    attributes = {started_at: self.started_at, stopped_at: self.stopped_at, product_way_attributes: {road: params[:product].actor}, first_producer: params[:first_producer].actor, second_producer: params[:second_producer].actor}
    for indicator_name in params[:product].actor.whole_indicators_list
      attributes[:product_way_attributes][indicator_name] = params[:product].send(indicator_name)
    end
    self.product_mixings.create!(attributes)
  end

  def perform_triple_mixing(reference, params)
    attributes = {started_at: self.started_at, stopped_at: self.stopped_at, product_way_attributes: {road: params[:product].actor}, first_producer: params[:first_producer].actor, second_producer: params[:second_producer].actor, third_producer: params[:third_producer].actor}
    for indicator_name in params[:product].actor.whole_indicators_list
      attributes[:product_way_attributes][indicator_name] = params[:product].send(indicator_name)
    end
    self.product_triple_mixings.create!(attributes)
  end

  def perform_quadruple_mixing(reference, params)
    attributes = {started_at: self.started_at, stopped_at: self.stopped_at, product_way_attributes: {road: params[:product].actor}, first_producer: params[:first_producer].actor, second_producer: params[:second_producer].actor, third_producer: params[:third_producer].actor, fourth_producer: params[:fourth_producer].actor}
    for indicator_name in params[:product].actor.whole_indicators_list
      attributes[:product_way_attributes][indicator_name] = params[:product].send(indicator_name)
    end
    self.product_quadruple_mixings.create!(attributes)
  end

  def perform_quintuple_mixing(reference, params)
    attributes = {started_at: self.started_at, stopped_at: self.stopped_at, product_way_attributes: {road: params[:product].actor}, first_producer: params[:first_producer].actor, second_producer: params[:second_producer].actor, third_producer: params[:third_producer].actor, fourth_producer: params[:fourth_producer].actor, fifth_producer: params[:fifth_producer].actor}
    for indicator_name in params[:product].actor.whole_indicators_list
      attributes[:product_way_attributes][indicator_name] = params[:product].send(indicator_name)
    end
    self.product_quintuple_mixings.create!(attributes)
  end

  # == Linkages

  def perform_attachment(reference, params)
    self.product_linkages.create!(started_at: self.stopped_at, point: params[:point].actor, carrier: params[:carrier].actor, carried: params[:carried].actor, nature: "occupied")
  end

  def perform_detachment(reference, params)
    if linkage = params[:carrier].actor.linkages.at(self.started_at).where(carried_id: params[:carried].actor.id).first
      self.product_linkages.create!(started_at: self.stopped_at, carrier: params[:carrier].actor, point: linkage.point, nature: "available")
    end
  end

  def perform_simple_attachment(reference, params)
    self.product_linkages.create!(started_at: self.stopped_at, point: params[:carrier].actor.linkage_points.first, carrier: params[:carrier].actor, carried: params[:carried].actor, nature: "occupied")
  end

  def perform_simple_detachment(reference, params)
    self.product_linkages.create!(started_at: self.stopped_at, carrier: params[:carrier].actor, point: params[:point].actor, nature: "available")
  end

  # == Memberships

  def perform_group_inclusion(reference, params)
    self.product_memberships.create!(started_at: self.stopped_at, member: params[:member].actor, group: params[:group].actor, nature: "interior")
  end

  def perform_group_exclusion(reference, params)
    self.product_memberships.create!(started_at: self.stopped_at, member: params[:member].actor, group: params[:group].actor, nature: "exterior")
  end

  # == Ownerships

  def perform_ownership_loss(reference, params)
    self.product_ownerships.create!(started_at: self.stopped_at, nature: :unknown, product: params[:product].actor)
  end

  def perform_ownership_change(reference, params)
    self.product_ownerships.create!(started_at: self.stopped_at, product: params[:product].actor, owner: params[:owner].actor)
  end

  # == Browsings

  def perform_browsing(reference, params)
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
    reading_task = self.product_reading_tasks.build(attributes.merge(product: indicatus.actor, indicator_name: indicatus.name, started_at: self.stopped_at))
    if indicatus.value?
      unless value = indicatus.computed_value
        raise "Cannot measure #{indicatus.inspect}."
      end
    else
      if self.intervention.parameters.is_a?(Hash) and self.intervention.parameters[:readings].is_a?(Hash) and value = self.intervention.parameters[:readings][reference.uid]
        if indicatus.indicator.datatype == :measure
          value = value[:value].to_f.in(value[:unit])
        end
      end
      # Rails.logger.warn("Measure without value are not possible for now")
    end
    unless value
      raise "Need a value for #{reference.expression} (#{indicatus.inspect})."
    end
    reading_task.value = value
    reading_task.save!
  end


end

