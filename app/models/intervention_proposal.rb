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
# == Table: intervention_proposals
#
#  activity_production_id                       :integer(4)
#  activity_production_irregular_batch_id       :integer(4)
#  area                                         :decimal(, )
#  batch_number                                 :integer(4)
#  created_at                                   :datetime         not null
#  estimated_date                               :date
#  id                                           :integer(4)       not null, primary key
#  number                                       :integer(4)
#  target                                       :string
#  technical_itinerary_intervention_template_id :integer(4)
#  updated_at                                   :datetime         not null
#

class InterventionProposal < ApplicationRecord
  belongs_to :technical_itinerary_intervention_template, class_name: 'TechnicalItineraryInterventionTemplate', required: true
  belongs_to :activity_production, class_name: 'ActivityProduction', required: true
  belongs_to :irregular_batch, class_name: 'ActivityProductionIrregularBatch', foreign_key: :activity_production_irregular_batch_id

  has_one :intervention, class_name: 'Intervention'
  has_many :parameters, class_name: 'InterventionProposal::Parameter', dependent: :destroy

  validates :estimated_date, :area, :number, presence: true

  before_validation :update_sequence, on: :create

  def update_sequence
    sequence = Sequence.of(:interventions)
    sequence.next_value!

    self.number = sequence.last_value
  end

  scope :after_date, ->(date) { where('estimated_date > ?', date) if date.present? }

  scope :without_numbers, ->(numbers) { where.not(number: numbers) if numbers.present? }

  scope :between_date, lambda { |from, to|
    where(estimated_date: from..to) if from.present? && to.present?
  }

  scope :of_land_parcel, lambda { |land_parcel_id|
    if land_parcel_id.present?
      joins(:activity_production)
      .where(activity_productions: { support_id: land_parcel_id })
    end
  }

  scope :of_worker_type, lambda { |worker_id|
    if worker_id.present?
      nature_name = Worker.find(worker_id).nature.name
      joins({ technical_itinerary_intervention_template: { intervention_template: { product_parameters: :product_nature } } })
      .where(product_natures: { name: nature_name })
    end
  }

  scope :of_equipment_type, lambda { |equipment_id|
    if equipment_id.present?
      equipment_name = Equipment.find(equipment_id).nature.name
      joins({ technical_itinerary_intervention_template: { intervention_template: { product_parameters: :product_nature } } })
      .where(product_natures: { name: equipment_name })
    end
  }

  scope :of_product_types, lambda { |products|
                             product_natures = Product.where(id: products).includes(:nature).map { |p| p.nature.name }
                             if product_natures.present?
                               joins({ technical_itinerary_intervention_template: { intervention_template: { product_parameters: :product_nature } } })
                               .where(product_natures: { name: product_natures })
                             end
                           }

  scope :of_activity, lambda { |activity_id|
    if activity_id.present?
      joins({ technical_itinerary_intervention_template: :technical_itinerary })
      .where(technical_itineraries: { activity_id: activity_id })
    end
  }

  scope :of_procedure, lambda { |procedure_name|
    if procedure_name.present?
      joins({ technical_itinerary_intervention_template: :intervention_template })
      .where(intervention_templates: { procedure_name: procedure_name })
    end
  }

  scope :of_product_parameter_or_nil, lambda { |parameter_id|
    if parameter_id.present?
      proposals = find_by_sql(["SELECT intervention_proposals.* FROM intervention_proposals
        LEFT OUTER JOIN intervention_proposal_parameters
        ON intervention_proposal_parameters.intervention_proposal_id = intervention_proposals.id
        WHERE intervention_proposal_parameters.id
        IS NULL
        OR intervention_proposal_parameters.product_id = ?
        OR intervention_proposal_parameters.product_id = ?", nil, parameter_id])
    end

    where(id: proposals.map(&:id)) if proposals.present?
  }

  scope :of_batch_number, ->(batch_number) { where(batch_number: batch_number) if batch_number.present? }

  scope :of_irregulat_batch, ->(irregular_batch) { where(irregular_batch: irregular_batch) if irregular_batch.present? }

  def estimated_working_time(target_parcel = nil)
    if target_parcel.nil?
      return area / technical_itinerary_intervention_template&.intervention_template&.workflow&.to_d
    end

    target_parcel.calculate_net_surface_area.to_d / technical_itinerary_intervention_template&.intervention_template&.workflow.to_d
  end

  def human_estimated_working_time(target_parcel = nil)
    t = estimated_working_time(target_parcel) * 3600
    hours = t / 3600
    minutes = (t / 60) % 60
    "#{format '%02d', hours.to_i} : #{format '%02d', minutes.to_i}"
  end

  def procedure
    procedure_name = technical_itinerary_intervention_template
                     .intervention_template
                     .procedure_name

    Procedo.find(procedure_name)
  end

  def name
    procedure_human_name = technical_itinerary_intervention_template.intervention_template.procedure.human_name
    "#{procedure_human_name} n°#{number}"
  end
end
