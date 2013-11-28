# -*- coding: utf-8 -*-
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
  belongs_to :intervention, inverse_of: :operations
  # has_many :tasks, class_name: "OperationTask", inverse_of: :operation, dependent: :destroy
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

  # after_save do
  #   self.intervention.save!
  # end

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

  def self.averages_of_periods(column = :duration, reference_date_column = :started_at, period = :month)
    self.calculate_in_periods(:avg, column, reference_date_column, period)
  end

  def self.sums_of_periods(column = :duration, reference_date_column = :started_at, period = :month)
    self.calculate_in_periods(:sum, column, reference_date_column, period)
  end

  def self.calculate_in_periods(operation, column, reference_date_column, period = :month)
    period = :doy if period == :day
    operation_date_column = "#{Operation.table_name}.#{reference_date_column}"
    expr = "EXTRACT(YEAR FROM #{operation_date_column})*1000 + EXTRACT(#{period} FROM #{operation_date_column})"
    self.group(expr).reorder(expr).select("#{expr} AS expr, #{operation}(#{column}) AS #{column}")
  end

  def description
    self.reference.human_expressions.to_sentence
  end

  private

  def task_actors(task)
    return task.parameters.inject({}) do |hash, pair|
      parameter = pair.second
      hash[pair.first] = if parameter.is_a?(Procedo::Variable)
                           self.casts.find_by!(reference_name: parameter.name.to_s).actor
                         elsif parameter.is_a?(Procedo::Indicator)
                           [self.casts.find_by!(reference_name: parameter.stakeholder.name.to_s).actor, parameter.indicator]
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
      raise TaskPerformingError, "Cannot perform #{task.action.type} (#{task.expression}) with #{task_actors(task).inspect}"
    end
  end

  def cancel(task)
    method_name = "cancel_#{task.action.type}"
    if respond_to?(method_name)
      send(method_name, task_actors(task))
    end
  end


  # == Localizations

  def perform_direct_movement(actors)
    self.product_localizations.create!(started_at: self.started_at, nature: :interior, product_id: actors[:product].id, container_id: actors[:localizable].container(self.started_at).id)
  end

  def perform_direct_entering(actors)
    self.product_localizations.create!(started_at: self.started_at, nature: :interior, product_id: actors[:product].id, container_id: actors[:localizable].id)
  end

  def perform_movement(actors)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: actors[:product].id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product_id: actors[:product].id, container_id: actors[:localizable].container(self.stopped_at).id)
  end

  def perform_entering(actors)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: actors[:product].id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product_id: actors[:product].id, container_id: actors[:localizable].id)
  end

  def perform_home_coming(actors)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: actors[:product].id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product_id: actors[:product].id, container_id: actors[:product].default_storage.id)
  end

  def perform_given_home_coming(actors)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: actors[:product].id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :interior, product_id: actors[:product].id, container_id: actors[:localizable].default_storage.id)
  end

  def perform_out_going(actors)
    self.product_localizations.create!(started_at: self.started_at, nature: :transfer, product_id: actors[:product].id)
    self.product_localizations.create!(started_at: self.stopped_at, nature: :exterior, product_id: actors[:product].id)
  end

  # == Births

  def perform_creation(actors)
    self.product_births.create!(started_at: self.started_at, stopped_at: self.stopped_at, nature: :creation, product: actors[:product], producer: actors[:producer])
  end

  def perform_division(actors)
    self.product_births.create!(started_at: self.started_at, stopped_at: self.stopped_at, nature: :division, product: actors[:product], producer: actors[:producer])
  end

  # == Deaths

  def perform_consumption(actors)
    self.product_deaths.create!(started_at: self.started_at, stopped_at: self.stopped_at, nature: :consumption, product: actors[:product], absorber: actors[:absorber])
  end

  def perform_merging(actors)
    self.product_deaths.create!(started_at: self.started_at, stopped_at: self.stopped_at, nature: :merging, product: actors[:product], absorber: actors[:absorber])
  end

  # == Linkages

  def perform_attachment(actors)
    self.product_linkages.create!(started_at: self.stopped_at, point: actors[:point], carrier: actors[:carrier], carried: actors[:carried], nature: "occupied")
  end

  def perform_detachment(actors)
    if linkage = actors[:carrier].linkages.at(self.started_at).where(carried_id: actors[:carried].id).first
      self.product_linkages.create!(started_at: self.stopped_at, carrier: actors[:carrier], point: linkage.point, nature: "available")
    end
  end

  def perform_simple_attachment(actors)
    self.product_linkages.create!(started_at: self.stopped_at, point: actors[:carrier].linkage_points_array.first, carrier: actors[:carrier], carried: actors[:carried], nature: "occupied")
  end

  def perform_simple_detachment(actors)
    self.product_linkages.create!(started_at: self.stopped_at, carrier: actors[:carrier], point: actors[:point], nature: "available")
  end

  # == Memberships

  def perform_group_inclusion(actors)
    self.product_memberships.create!(started_at: self.stopped_at, member: actors[:member], group: actors[:group], nature: "interior")
  end

  def perform_group_exclusion(actors)
    self.product_memberships.create!(started_at: self.stopped_at, member: actors[:member], group: actors[:group], nature: "exterior")
  end

  # == Ownerships

  def perform_ownership_loss(actors)
    self.product_ownerships.create!(started_at: self.stopped_at, nature: :unknown, product_id: actors[:product].id)
  end

  def perform_ownership_change(actors)
    self.product_ownerships.create!(started_at: self.stopped_at, product_id: actors[:product].id, owner: actors[:owner])
  end

  # == Browsings

  def perform_browsing(actors)
  end

  # == Measurements

  def perform_measurement(actors)
  end

  def perform_simple_measurement(actors)
    # product, indicator = actors[:indicator]
    # self.product_measurements.create!(product: product, indicator: indicator)
  end

end

