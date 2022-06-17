# frozen_string_literal: true

# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2022 Ekylibre SAS
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
# == Table: intervention_templates
#
#  active                          :boolean          default(TRUE)
#  campaign_id                     :integer
#  created_at                      :datetime         not null
#  creator_id                      :integer
#  description                     :string
#  id                              :integer          not null, primary key
#  intervention_model_id           :string
#  name                            :string
#  originator_id                   :integer
#  preparation_time_hours          :integer
#  preparation_time_minutes        :integer
#  procedure_name                  :string
#  technical_workflow_procedure_id :string
#  updated_at                      :datetime         not null
#  updater_id                      :integer
#  workflow                        :decimal(, )
#

class InterventionTemplate < ApplicationRecord
  # Relation
  has_many :product_parameters, class_name: ::InterventionTemplate::ProductParameter, foreign_key: :intervention_template_id, dependent: :destroy
  # Joins table with activities
  has_many :association_activities, class_name: ::InterventionTemplateActivity, foreign_key: :intervention_template_id, dependent: :destroy
  has_many :activities, through: :association_activities

  has_many :technical_itinerary_intervention_templates, dependent: :destroy, class_name: ::TechnicalItineraryInterventionTemplate
  has_many :technical_itineraries, through: :technical_itinerary_intervention_templates

  belongs_to :campaign
  belongs_to :originator, class_name: ::InterventionTemplate
  has_one :linked_intervention_template, class_name: ::InterventionTemplate, foreign_key: 'originator_id', dependent: :nullify

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :active, inclusion: { in: [true, false] }, allow_blank: true
  validates :description, :name, :procedure_name, length: { maximum: 500 }, allow_blank: true
  validates :preparation_time_hours, :preparation_time_minutes, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :workflow, numericality: true, allow_blank: true
  # ]VALIDATORS]
  validates :name, :procedure_name, :workflow, :campaign, presence: true
  validate :campaign_id_not_changed, if: :campaign_id_changed?, on: :update
  validate on: :create do
    if originator && originator.linked_intervention_template.present?
      errors.add(:originator, :already_have_linked_intervention_template)
    end
  end

  # Nested attributes
  accepts_nested_attributes_for :product_parameters, allow_destroy: true
  accepts_nested_attributes_for :association_activities, allow_destroy: true

  attr_accessor :is_planting, :is_harvesting

  before_validation do
    # Remove duplicate association
    activity_id = []
    association_activities.each do |association|
      if activity_id.include?(association.activity_id)
        association.destroy
      else
        activity_id << association.activity_id
      end
    end
  end

  after_update do
    technical_itineraries.includes(:activity_productions).each(&:update_daily_charges)
  end

  protect(on: :destroy) do
    technical_itineraries.any?
  end

  def is_duplicatable?
    linked_intervention_template.nil?
  end

  def self.duplicate_collection(campaign)
    all.map do |intervention_template|
      new_intervention_template = intervention_template.instanciate_duplicate(campaign)
      new_intervention_template.save
      new_intervention_template
    end
  end

  def instanciate_duplicate(campaign)
    new_intervention_template = self.dup
    product_parameters.each do |product_parameter|
      duplicate_product_parameter = product_parameter.dup
      duplicate_product_parameter.intervention_template_id = nil
      new_intervention_template.product_parameters << duplicate_product_parameter
    end
    association_activities.each do |association_activity|
      duplicate_association_activity = association_activity.dup
      duplicate_association_activity.intervention_template_id = nil
      new_intervention_template.association_activities << duplicate_association_activity
    end
    new_intervention_template.campaign = campaign
    new_intervention_template.originator = self
    new_intervention_template
  end

  def label
    tc(:label, campaign: campaign.name, name: name) if campaign && name
  end

  # The Procedo::Procedure behind intervention
  def procedure
    Procedo.find(procedure_name)
  end

  def planting?
    Procedo::Procedure.of_category(:planting)
      .map(&:categories).include?(procedure.categories)
  end

  def harvesting?
    Procedo::Procedure.of_category(:harvesting)
      .map(&:categories).include?(procedure.categories)
  end

  def attributes
    super.merge(is_planting: '', is_harvesting: '')
  end

  def list_of_activities
    activities.map(&:name).join(', ')
  end

  def preparation_time
    "#{preparation_time_hours.to_i || 0} h #{preparation_time_minutes || 0} min"
  end

  def total_cost(area = 1.0)
    (doer_cost(area) + tool_cost(area) + input_cost(area)).round(2)
  end

  def doer_cost(area = 1.0)
    cost = 0.0
    if doers.any?
      if preparation_time_hours
        cost += ( preparation_time_hours * doers.map{ |i| i.cost_amount_computation.amount }.compact.sum )
      end
      cost += ( (time_per_hectare * area) * doers.map{ |i| i.cost_amount_computation.amount }.compact.sum )
    end
    cost
  end

  def tool_cost(area = 1.0)
    cost = 0.0
    if tools.any?
      cost += (time_per_hectare * area) * tools.map{ |i| i.cost_amount_computation.amount.to_d }.compact.sum
    end
    cost
  end

  def input_cost(area = 1.0)
    cost = 0.0
    if inputs.any?
      cost += area * inputs.map{ |i| i.cost_amount_computation.amount.to_d }.compact.sum
    end
    cost
  end

  def self.used_procedures
    select(:procedure_name).distinct.pluck(:procedure_name).map do |name|
      Procedo.find(name)
    end.compact
  end

  def time_per_hectare
    (1.0 / workflow)
  end

  def human_time_per_hectare
    t = time_per_hectare * 3600.0
    hours = (t / (60 * 60)).to_i
    minutes = ((t / 60) % 60).to_i
    "#{hours} h #{minutes} min"
  end

  def human_workflow
    "#{workflow.round(2).l(precision: 2)} #{:hectare_hours.tl}"
  end

  def tools
    procedure_tool = procedure.parameters.map{ |p| p.name if (p.class == Procedo::Procedure::ProductParameter && p.tool?) }.compact
    product_parameters.where("procedure ->> 'type' IN (?)", procedure_tool)
  end

  def doers
    procedure_doer = procedure.parameters.map{ |p| p.name if (p.class == Procedo::Procedure::ProductParameter && p.doer?) }.compact
    product_parameters.where("procedure ->> 'type' IN (?)", procedure_doer)
  end

  def inputs
    procedure_input = procedure.parameters.map{ |p| p.name if (p.class == Procedo::Procedure::ProductParameter && p.input?) }.compact
    product_parameters.where("procedure ->> 'type' IN (?)", procedure_input)
  end

  def outputs
    procedure_output = procedure.parameters.map{ |p| p.name if (p.class == Procedo::Procedure::ProductParameter && p.output?) }.compact
    product_parameters.where("procedure ->> 'type' IN (?)", procedure_output)
  end

  def quantity_of_parameter(product_parameter, area)
    unless %i[input output].include?(product_parameter.find_general_product_type)
      return time_per_hectare * product_parameter.quantity * area
    end

    if product_parameter.unit_per_area? || product_parameter.unit == 'unit'
      return product_parameter.quantity_in_unit(area)
    end

    product_parameter.quantity
  end

  class << self
    def import_from_lexicon(technical_workflow_procedure:, intervention_model:, campaign: )
      if it = InterventionTemplate.find_by(campaign_id: campaign.id, intervention_model_id: intervention_model.id, technical_workflow_procedure_id: technical_workflow_procedure.id)
        return it
      end
      unless twp = TechnicalWorkflowProcedure.find(technical_workflow_procedure)
        raise ArgumentError.new("The TWP #{technical_workflow_procedure.inspect} is not known")
      end

      unless im = InterventionModel.find(intervention_model)
        raise ArgumentError.new("The IM #{intervention_model.inspect} is not known")
      end

      it = new(
        procedure_name: im.procedure_reference,
        campaign_id: campaign.id,
        intervention_model_id: im.id,
        technical_workflow_procedure_id: twp.id,
        name: im.name[Preference[:language]],
        active: true,
        description: :set_by_lexicon.tl,
        workflow: im.working_flow # hectare_per_hour or see in im.working_flow_unit
      )

      unless it.save
        raise "Cannot create intervention template from Lexicon #{technical_workflow.inspect}: #{it.errors.full_messages.join(', ')}"
      end

      it
    end
  end

  private

    def campaign_id_not_changed
      errors.add(:campaign, 'change_not_allowed')
    end
end
