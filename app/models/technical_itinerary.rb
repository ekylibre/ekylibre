# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: technical_itineraries
#
#  activity_id    :integer(4)
#  campaign_id    :integer(4)
#  created_at     :datetime         not null
#  creator_id     :integer(4)
#  description    :string
#  id             :integer(4)       not null, primary key
#  name           :string
#  originator_id  :integer(4)
#  plant_density  :decimal(19, 4)
#  reference_name :string
#  updated_at     :datetime         not null
#  updater_id     :integer(4)
#

class TechnicalItinerary < ApplicationRecord
  has_many :itinerary_templates, class_name: 'TechnicalItineraryInterventionTemplate', dependent: :destroy
  has_many :intervention_templates, through: :itinerary_templates, class_name: 'InterventionTemplate'

  has_many :activity_productions, class_name: 'ActivityProduction', foreign_key: :technical_itinerary_id

  belongs_to :campaign
  belongs_to :activity
  belongs_to :technical_workflow, class_name: 'TechnicalWorkflow', foreign_key: :reference_name
  has_many :tactics, class_name: 'ActivityTactic', foreign_key: :technical_itinerary_id

  belongs_to :originator, class_name: 'TechnicalItinerary'
  has_one :linked_technical_itinerary, class_name: 'TechnicalItinerary', foreign_key: 'originator_id', dependent: :nullify

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :description, :name, length: { maximum: 500 }, allow_blank: true
  # ]VALIDATORS]
  validates :activity, presence: true
  validates :name, :campaign_id, presence: true
  validate :campaign_id_not_changed, if: :campaign_id_changed?, on: :update

  validate on: :create do
    if originator && originator.linked_technical_itinerary.present?
      errors.add(:originator, :already_have_linked_technical_itinerary)
    end
  end

  accepts_nested_attributes_for :itinerary_templates, allow_destroy: true

  scope :of_campaign, lambda { |campaign| where(campaign: campaign)}

  scope :of_activity, lambda { |activity| where(activity: activity)}

  after_update do
    update_daily_charges
  end

  protect(on: :destroy) do
    activity_productions.any?
  end

  def is_duplicatable?
    linked_technical_itinerary.nil?
  end

  def update_daily_charges
    activity_productions.each do |activity_production|
      TechnicalItineraries::DailyChargesCreationInteractor
        .call({ activity_production: activity_production })
    end
  end

  def duration
    harvest_end_position = 0
    last_position = 0
    if itinerary_templates.present?
      last_position = 1
      itinerary_templates.includes(:intervention_template).order(position: :asc).each do |itinerary_template|
        last_position += itinerary_template.day_between_intervention || 0
        if itinerary_template.intervention_template.harvesting?
          harvest_end_position = last_position + (itinerary_template.duration.nil? ? 0 : itinerary_template.duration - 1)
        end
      end
      last_position > harvest_end_position ? last_position : harvest_end_position
    else
      0
    end
  end

  def human_duration
    "#{duration} j"
  end

  def average_yield
    harvest_procedures = Procedo::Procedure.of_action(:harvest).map(&:name)
    intervention_template = intervention_templates.find_by(procedure_name: harvest_procedures)
    if intervention_template.present?
      product_parameter = intervention_template.product_parameters.where("procedure ->> 'type' = ?", 'matters')&.first
      "#{product_parameter&.quantity&.l(precision: 1)} #{product_parameter.unit_symbol}" if product_parameter.present?
    end
  end

  def total_cost
    if activity_productions.any?
      area = activity_productions&.map(&:net_surface_area)&.sum&.convert(:hectare)
    else
      area = 1.0
    end
    intervention_templates.group(:id).count(:id).map do |id, repetition|
      intervention_template = intervention_templates.find(id)
      repetition * intervention_template.total_cost(area.to_f)
    end.compact.sum.round(2)
  end

  def global_workload
    total = 0.000
    intervention_templates.each do |it|
      total += it.time_per_hectare
    end
    total.to_d.round(2)
  end

  def human_global_workload
    a = ActiveSupport::Duration.build(global_workload * 3600)
    "#{a.in_full(:hour)} h #{a.parts[:minutes]} min"
  end

  def parameter_worload(nature)
    result = 0
    if %i[tools doers].include?(nature)
      self.intervention_templates.each do |it|
        elements = it.send(nature)
        elements.each do |element|
          result += (element.quantity * it.time_per_hectare)
        end
      end
    end
    result.to_d.round(2)
  end

  def human_parameter_workload(nature)
    "#{parameter_worload(nature).l(precision: 2)} #{:hours_hectare.tl}"
  end

  class << self

    def import_from_lexicon(reference_name, force = false, harvest_year = nil)
      campaign = Campaign.find_by_harvest_year(harvest_year.to_i) if harvest_year
      unless campaign
        raise ArgumentError.new("The technical workflow can't be imported without harvest_year#{harvest_year.inspect}")
      end
      unless tw = TechnicalWorkflow.find_by_reference_name(reference_name)
        raise ArgumentError.new("The technical workflow ID #{reference_name.inspect} is not known")
      end

      ti = TechnicalItinerary.find_by(campaign: campaign, reference_name: reference_name)
      return ti if ti

      unless activity = Activity.find_by(reference_name: tw.production_reference_name)
        activity = Activity.import_from_lexicon(tw.production_reference_name)
      end

      ti = self.create_blank_ti(tw, campaign, activity)
      temp_pn = ProductNature.first
      creation_service = TechnicalItineraries::Itk::CreateTactic.new(activity: activity, technical_workflow: tw, campaign: campaign)
      tiit_ids = creation_service.create_procedures_and_intervention_templates(ti, temp_pn)
      TechnicalItineraryInterventionTemplate.where(id: tiit_ids).each(&:compute_day_between_intervention)
      ti
    end

    def import_from_lexicon_with_activity_and_campaign(campaign:, activity:, technical_workflow_id:)
      if ti = TechnicalItinerary.find_by(campaign: campaign, activity: activity, reference_name: technical_workflow_id)
        return ti
      end
      unless tw = TechnicalWorkflow.find_by_reference_name(technical_workflow_id)
        raise ArgumentError.new("The technical workflow reference_name #{technical_workflow_id.inspect} is not known")
      end

      self.create_blank_ti(tw, campaign, activity)
    end

    def create_blank_ti(tw, campaign, activity)
      ti = new(
        name: tw.translation.send(Preference[:language]),
        campaign_id: campaign.id,
        activity_id: activity.id,
        description: :set_by_lexicon.tl,
        reference_name: tw.reference_name,
        plant_density: tw.plant_density&.to_f
      )

      unless ti.save
        raise "Cannot create technical itinerary from Lexicon #{technical_workflow.inspect}: #{ti.errors.full_messages.join(', ')}"
      end

      ti
    end

  end

  private

    def campaign_id_not_changed
      errors.add(:campaign, 'change_not_allowed')
    end
end
