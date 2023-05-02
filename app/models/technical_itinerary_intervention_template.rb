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
# == Table: technical_itinerary_intervention_templates
#
#  created_at               :datetime         not null
#  day_between_intervention :integer(4)
#  day_since_start          :decimal(19, 4)
#  dont_divide_duration     :boolean          default(FALSE)
#  duration                 :integer(4)
#  frequency                :string           default("per_year"), not null
#  id                       :integer(4)       not null, primary key
#  intervention_template_id :integer(4)
#  parent_hash              :string
#  position                 :integer(4)
#  reference_hash           :string
#  repetition               :integer(4)       default(1), not null
#  technical_itinerary_id   :integer(4)
#  updated_at               :datetime         not null
#

class TechnicalItineraryInterventionTemplate < ApplicationRecord
  enumerize :frequency, in: %i[per_day per_month per_year], predicates: true, default: :per_year
  belongs_to :technical_itinerary, class_name: 'TechnicalItinerary'
  belongs_to :intervention_template, class_name: 'InterventionTemplate'

  has_many :intervention_proposals, class_name: 'InterventionProposal'

  # belongs_to :parent, -> { where(reference_hash: self.parent_hash)}
  # has_many :childs, ->(child) { where(reference_hash: child.parent_hash)}

  attr_accessor :intervention_template_name, :is_planting, :is_harvesting, :procedure_name

  validates :position, presence: true

  before_validation do
    self.frequency ||= :per_year
    self.repetition ||= 1
  end

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

  # return the repetition of the item for the budget
  def year_repetition
    if per_year?
      repetition
    elsif per_month?
      repetition * 12
    elsif per_day?
      repetition * 365
    else
      1
    end
  end

  # return the number of day between repetition
  def day_gap
    if year_repetition != 0
      365 / year_repetition
    else
      365
    end
  end

  def day_compare_to_planting
    tiit = TechnicalItineraryInterventionTemplate.where(technical_itinerary: technical_itinerary).order(:position)

    planting = nil
    tiit.includes(:intervention_template).each do |ti|
      planting = ti if ti.intervention_template.planting?
    end

    if planting.nil?
      '-'
    elsif position < planting.position
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
    if position == 0
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

  def inputs_or_outputs
    intervention_template.human_inputs_or_outputs_quantity
  end
end
