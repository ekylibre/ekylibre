# frozen_string_literal: true

class TechnicalItineraryInterventionTemplate < ApplicationRecord
  belongs_to :technical_itinerary, class_name: TechnicalItinerary
  belongs_to :intervention_template, class_name: InterventionTemplate

  has_many :intervention_proposals, class_name: InterventionProposal

  # belongs_to :parent, -> { where(reference_hash: self.parent_hash)}
  # has_many :childs, ->(child) { where(reference_hash: child.parent_hash)}

  attr_accessor :intervention_template_name, :is_planting, :is_harvesting, :procedure_name

  validates :position, presence: true

  # Need to access intervention_template_name in js
  def attributes
    super.merge(intervention_template_name: '', is_planting: '', is_harvesting: '', procedure_name: '')
  end

  def parent
    if parent_hash.present?
      TechnicalItineraryInterventionTemplate.find_by(reference_hash: parent_hash)
    else
      nil
    end
  end

  def childs
    if reference_hash.present?
      TechnicalItineraryInterventionTemplate.where(parent_hash: reference_hash)
    else
      []
    end
  end

  def day_compare_to_planting
    tiit = TechnicalItineraryInterventionTemplate.where(technical_itinerary: technical_itinerary).order(:position)

    planting = nil
    tiit.includes(:intervention_template).each do |ti|
      planting = ti if ti.intervention_template.planting?
    end

    return '-' if planting.nil?

    if position < planting.position
      tiit = tiit.where(position: (position + 1)..(planting.position))
      - tiit.sum(:day_between_intervention)
    else
      tiit = tiit.where(position: (planting.position + 1)..(position))
      tiit.sum(:day_between_intervention)
    end
  end

  def compute_day_between_intervention
    previous_tiit = TechnicalItineraryInterventionTemplate.where(technical_itinerary: technical_itinerary).where(position: (position - 1)).first
    ante_previous_tiit = TechnicalItineraryInterventionTemplate.where(technical_itinerary: technical_itinerary).where(position: (position - 2)).first
    # first intervention on ITK
    if position == 1
      day_b_i = 0
    # second or more intervention on ITK with previous exist and day_since_start
    elsif previous_tiit && previous_tiit.day_since_start && day_since_start
      day_b_i = (day_since_start - previous_tiit.day_since_start).to_f.to_i
    # second or more intervention on ITK with anteprevious exist and day_since_start
    elsif ante_previous_tiit && ante_previous_tiit.day_since_start && day_since_start
      day_b_i = (day_since_start - ante_previous_tiit.day_since_start).to_f.to_i
    end
    self.day_between_intervention = day_b_i
    self.save!
  end

  def human_day_compare_to_planting
    "#{day_compare_to_planting} j"
  end

  def human_day_between_intervention
    "#{day_between_intervention} j"
  end
end
