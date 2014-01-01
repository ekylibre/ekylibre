# -*- coding: utf-8 -*-
# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: operations
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  duration        :integer
#  id              :integer          not null, primary key
#  intervention_id :integer          not null
#  lock_version    :integer          default(0), not null
#  reference_name  :string(255)      not null
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
  has_many :product_births,        dependent: :destroy
  has_many :product_deaths,        dependent: :destroy
  has_many :product_enjoyments,    dependent: :destroy
  has_many :product_linkages,      dependent: :destroy
  has_many :product_localizations, dependent: :destroy
  has_many :product_measurements,  dependent: :destroy
  has_many :product_memberships,   dependent: :destroy
  has_many :product_ownerships,    dependent: :destroy

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :duration, allow_nil: true, only_integer: true
  validates_length_of :reference_name, allow_nil: true, maximum: 255
  validates_presence_of :intervention, :reference_name, :started_at, :stopped_at
  #]VALIDATORS]

  delegate :reference, to: :intervention, prefix: true
  delegate :casts, to: :intervention

  # default_scope -> { order(:started_at) }
  scope :unvalidateds, -> { where(:confirmed => false) }

  scope :of_campaign, lambda { |*campaigns|
    campaigns.flatten!
    for campaign in campaigns
      raise ArgumentError.new("Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}") unless campaign.is_a?(Campaign)
    end
    joins(intervention: :production).merge(Production.of_campaign(campaigns))
  }

  scope :of_activities, lambda { |*activities|
    activities.flatten!
    for activity in activities
      raise ArgumentError.new("Expected Activity, got #{activity.class.name}:#{activity.inspect}") unless activity.is_a?(Activity)
    end
    joins(intervention: :production).merge(Production.of_activities(activities))
  }

  calculable period: :month, at: :started_at, column: :duration

  before_validation(on: :create) do
    self.started_at ||= Time.now
    # TODO Remove following line!!!
    self.stopped_at ||= self.started_at
    if self.started_at and self.stopped_at
      self.duration = (self.stopped_at - self.started_at).to_i
    end
  end

  before_update :cancel_all!
  after_save :perform_all!
  after_destroy :cancel_all!

  def perform_all!
    for task in self.reference.tasks.values
      perform(task)
    end
  end

  def cancel_all!
    for task in self.reference.tasks.values
      cancel(task)
    end
  end

  def reference
    self.intervention_reference.operations[self.reference_name]
  end

  def description
    self.reference.human_expressions.to_sentence
  end

  private

  def task_actors(task)
    return task.parameters.inject({}) do |hash, pair|
      parameter = pair.second
      hash[pair.first] = if parameter.is_a?(Procedo::Variable)
                           self.casts.find_by!(reference_name: parameter.name.to_s)
                         elsif parameter.is_a?(Procedo::VariableIndicator)
                           # [self.casts.find_by!(reference_name: parameter.stakeholder.name.to_s), parameter]
                           Indicatus.new(parameter, self)
                         else
                           raise StandardError, "Don't known how to find a #{parameter.class.name}"
                         end
      hash
    end
  end



  def perform(task)
    begin
      send("perform_#{task.action.type}", task_actors(task))
    rescue Exception => e
      raise TaskPerformingError, "Cannot perform #{task.action.type} (#{task.expression}) with #{task_actors(task).inspect}.\n#{e.message}.\n" + e.backtrace.join("\n")
    end
  end

  def cancel(task)
    method_name = "cancel_#{task.action.type}"
    if respond_to?(method_name)
      send(method_name, task_actors(task))
    end
  end


  # == Localizations

  def perform_direct_movement(params)
    self.product_localizations.create!(started_at: self.started_at, nature: :interior, product: params[:product].actor, container: params[:localizable].actor.localizations.at(self.started_at).first.container)
  end

  def perform_direct_entering(params)
    self.product_localizations.create!(started_at: self.started_at, nature: :interior, product: params[:product].actor, container: params[:localizable].actor)
  end

  def perform_movement(params)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product: params[:product].actor)
    localization = params[:localizable].actor.localizations.at(self.stopped_at).first
    while localization.container.nil?
      break unless localization = localization.previous
    end
    container = localization.container || params[:localizable].actor.default_storage
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product: params[:product].actor, container: container)
  end

  def perform_entering(params)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product: params[:product].actor)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product: params[:product].actor, container: params[:localizable].actor)
  end

  def perform_home_coming(params)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product: params[:product].actor)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product: params[:product].actor, container: params[:product].actor.default_storage)
  end

  def perform_given_home_coming(params)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product: params[:product].actor)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product: params[:product].actor, container: params[:localizable].actor.default_storage)
  end

  def perform_out_going(params)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product: params[:product].actor)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :exterior, product: params[:product].actor)
  end

  # == Births

  def perform_creation(params)
    self.product_births.create!(started_at: self.started_at, stopped_at: self.stopped_at, nature: :creation, product: params[:product].actor, producer: params[:producer].actor)
  end

  def perform_division(params)
    producer = params[:producer].actor
    attributes = {started_at: self.started_at, stopped_at: self.stopped_at, nature: :division, product: params[:product].actor, producer: producer}
    for indicator_name in producer.whole_indicators_list
      attributes[indicator_name] = params[:product].send(indicator_name)
    end
    self.product_births.create!(attributes)
  end

  # == Deaths

  def perform_consumption(params)
    self.product_deaths.create!(started_at: self.started_at, stopped_at: self.stopped_at, nature: :consumption, product: params[:product].actor, absorber: params[:absorber].actor)
  end

  def perform_merging(params)
    self.product_deaths.create!(started_at: self.started_at, stopped_at: self.stopped_at, nature: :merging, product: params[:product].actor, absorber: params[:absorber].actor)
  end

  # == Linkages

  def perform_attachment(params)
    self.product_linkages.create!(started_at: self.stopped_at, point: params[:point].actor, carrier: params[:carrier].actor, carried: params[:carried].actor, nature: "occupied")
  end

  def perform_detachment(params)
    if linkage = params[:carrier].actor.linkages.at(self.started_at).where(carried_id: params[:carried].actor.id).first
      self.product_linkages.create!(started_at: self.stopped_at, carrier: params[:carrier].actor, point: linkage.point, nature: "available")
    end
  end

  def perform_simple_attachment(params)
    self.product_linkages.create!(started_at: self.stopped_at, point: params[:carrier].actor.linkage_points_list.first, carrier: params[:carrier].actor, carried: params[:carried].actor, nature: "occupied")
  end

  def perform_simple_detachment(params)
    self.product_linkages.create!(started_at: self.stopped_at, carrier: params[:carrier].actor, point: params[:point].actor, nature: "available")
  end

  # == Memberships

  def perform_group_inclusion(params)
    self.product_memberships.create!(started_at: self.stopped_at, member: params[:member].actor, group: params[:group].actor, nature: "interior")
  end

  def perform_group_exclusion(params)
    self.product_memberships.create!(started_at: self.stopped_at, member: params[:member].actor, group: params[:group].actor, nature: "exterior")
  end

  # == Ownerships

  def perform_ownership_loss(params)
    self.product_ownerships.create!(started_at: self.stopped_at, nature: :unknown, product: params[:product].actor)
  end

  def perform_ownership_change(params)
    self.product_ownerships.create!(started_at: self.stopped_at, product: params[:product].actor, owner: params[:owner].actor)
  end

  # == Browsings

  def perform_browsing(params)
  end

  # == Measurements

  def perform_simple_measurement(params)
    indicatus = params[:indicator]
    if indicatus.value?
      measurement = self.product_measurements.build(product: indicatus.actor, indicator_name: indicatus.name, started_at: self.stopped_at)
      unless value = indicatus.computed_value
        raise "Cannot measure #{indicatus.inspect}."
      end
      measurement.value = indicatus.computed_value
      measurement.save!
    else
      Rails.logger.warn("Measure without value are not possible for now")
    end
  end

  def perform_measurement(params)
    return perform_simple_measurement(params)
    indicatus = params[:indicator]
    if indicatus.value?
      measurement = self.product_measurements.build(product: indicatus.actor, indicator_name: indicatus.name, started_at: self.stopped_at, reporter: params[:reporter].actor)
      measurement.value = indicatus.computed_value
      measurement.save!
    else
      Rails.logger.warn("Measure without value are not possible for now")
    end
  end

  def perform_assisted_measurement(params)
    return perform_simple_measurement(params)
    indicatus = params[:indicator]
    if indicatus.value?
      measurement = self.product_measurements.build(product: indicatus.actor, indicator_name: datum.name, started_at: self.stopped_at, reporter: params[:reporter].actor, reporter: params[:reporter].actor, tool: params[:tool].actor)
      measurement.value = datum.value
      measurement.save!
    else
      Rails.logger.warn("Measure without value are not possible for now")
    end
  end

end

