# frozen_string_literal: true

class TechnicalItinerary < ApplicationRecord
  has_many :itinerary_templates, class_name: TechnicalItineraryInterventionTemplate, dependent: :destroy
  has_many :intervention_templates, through: :itinerary_templates, class_name: InterventionTemplate

  has_many :activity_productions, class_name: ActivityProduction, foreign_key: :technical_itinerary_id

  belongs_to :campaign
  belongs_to :activity
  belongs_to :technical_workflow, class_name: TechnicalWorkflow
  has_many :tactics, class_name: 'ActivityTactic', foreign_key: :technical_itinerary_id
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  belongs_to :updater, class_name: 'User', foreign_key: 'updater_id'

  belongs_to :originator, class_name: TechnicalItinerary
  has_one :linked_technical_itinerary, class_name: TechnicalItinerary, foreign_key: 'originator_id', dependent: :nullify

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
    intervention_template = intervention_templates.find_by(procedure_name: 'harvesting')
    if intervention_template.present?
      product_parameter = intervention_template.product_parameters.where("procedure ->> 'type' = ?", 'matters')
        &.first
      "#{product_parameter&.quantity&.l(precision: 1)} #{product_parameter.unit_symbol}" if product_parameter.present?
    end
  end

  def total_cost
    if activity_productions.any?
      area = activity_productions&.map(&:net_surface_area)&.sum&.convert(:hectare)
    else
      area = 1.0
    end
    intervention_templates.map {|i| i.total_cost(area.to_f)}.compact.sum.round(2)
  end

  def global_workload
    total = 0.0
    intervention_templates.each do |it|
      total += it.time_per_hectare
    end
    total
  end

  def human_global_workload
    (Time.mktime(0)+ global_workload * 3600).strftime("%H h %M min")
  end

  def parameter_worload(type)
    if %i[tools doers].include?(type)
      result = 0
      intervention_templates.each do |it|
        elements = it.send(type)
        elements.each do |element|
          result += (element.quantity * it.time_per_hectare)
        end
      end
      result
    end
  end

  def human_parameter_workload(type)
    "#{parameter_worload(type).round(2).l(precision: 2)} #{:hours_hectare.tl}"
  end

  class << self

    def import_from_lexicon(campaign:, activity:, technical_workflow_id:)
      if ti = TechnicalItinerary.find_by(campaign: campaign, activity: activity, technical_workflow_id: technical_workflow_id)
        return ti
      end
      unless tw = TechnicalWorkflow.find(technical_workflow_id)
        raise ArgumentError.new("The TW ID #{technical_workflow_id.inspect} is not known")
      end

      ti = new(
        name: tw.translation.send(Preference[:language]),
        campaign_id: campaign.id,
        activity_id: activity.id,
        description: :set_by_lexicon.tl,
        technical_workflow_id: technical_workflow_id
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
