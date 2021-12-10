# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# == Table: worker_contracts
#
#  entity_id  :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class WorkerContract < ApplicationRecord
  include Customizable
  include Attachable

  belongs_to :entity, class_name: 'Entity', inverse_of: :worker_contracts
  belongs_to :contract_nature, primary_key: :reference_name, class_name: 'MasterDoerContract', foreign_key: :reference_name

  enumerize :nature, in: %i[permanent_worker temporary_worker external_staff], default: :permanent_worker, predicates: true

  validates :entity, :started_at, :monthly_duration, :raw_hourly_amount, presence: true

  scope :of_nature, ->(nature) { where(nature: nature) }

  scope :active_at, ->(started_at)  { where('started_at <= ? AND (stopped_at IS NULL OR stopped_at >= ?)', started_at, started_at) }

  scope :in_year, ->(year) { where('EXTRACT(YEAR FROM started_at) <= ? AND (stopped_at IS NULL OR EXTRACT(YEAR FROM stopped_at) >= ?)', year, year) }

  after_create do
    if Worker.find_by(person_id: entity.id).nil?
      Worker.create!(
        born_at: started_at,
        person: entity,
        name: entity.name,
        variant: ProductNatureVariant.import_from_lexicon(nature)
      )
    end
  end

  before_validation do
    self.name ||= contract_nature.translation.send(Preference[:language]) if contract_nature
  end

  def month_duration
    if stopped_at && (stopped_at - started_at) < 1.year
      (stopped_at - started_at).month
    else
      12
    end
  end

  # period (:hour, :month, :year)
  # mode (:net, :raw, :charged)
  def cost(period: :year, mode: :raw)
    return nil unless reference_name && MasterDoerContract.find_by(reference_name: reference_name)

    farm_charges_ratio = MasterDoerContract.find_by(reference_name: reference_name).farm_charges_ratio
    salary_charges_ratio = MasterDoerContract.find_by(reference_name: reference_name).salary_charges_ratio

    # compute ratio for mode (:net, :raw, :charged)
    if mode == :raw
      coef = 1.0
    elsif mode == :net
      coef = (1 - salary_charges_ratio)
    elsif mode == :charged
      coef = (1 + farm_charges_ratio)
    else
      coef = 0
    end
    # return cost for period (:hour, :month, :year)
    case period
    when :year
      cost = raw_hourly_amount * coef * (monthly_duration * month_duration)
    when :month
      cost = raw_hourly_amount * coef * monthly_duration
    when :hour
      cost = raw_hourly_amount * coef
    else
      cost = nil
    end
    cost&.round(2)
  end

  class << self

    def annual_cost(nature, campaign, permanent_salaried = true)
      cost = 0.0
      in_year(campaign.harvest_year).of_nature(nature).each do |contract|
        next if contract.salaried != permanent_salaried && contract.nature == 'permanent_worker'

        contract_value = contract.cost(period: :year, mode: :charged)
        cost += contract_value.to_f if contract_value.present?
      end
      cost
    end

    def import_from_lexicon(reference_name:, entity_id:, started_at: Time.now)
      unless item = MasterDoerContract.find_by_reference_name(reference_name)
        raise ArgumentError.new("The contract #{reference_name.inspect} is not known")
      end

      unless entity = Entity.find(entity_id)
        raise ArgumentError.new("The entity_id doesn't exist #{entity_id.inspect} is not known")
      end

      contract = new(
        name: item.translation.send(Preference[:language]),
        entity_id: entity.id,
        description: :import_from_lexicon.tl,
        reference_name: item.reference_name,
        nature: item.worker_variant,
        salaried: item.salaried,
        contract_end: item.contract_end,
        started_at: started_at,
        monthly_duration: item.legal_monthly_working_time,
        raw_hourly_amount: item.min_raw_wage_per_hour
      )

      unless contract.save
        raise "Cannot create contract from Lexicon #{reference_name.inspect}: #{contract.errors.full_messages.join(', ')}"
      end

      contract
    end
  end
end
