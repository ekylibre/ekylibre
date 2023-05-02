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
# == Table: worker_contracts
#
#  contract_end      :string
#  created_at        :datetime         not null
#  creator_id        :integer(4)
#  custom_fields     :jsonb
#  description       :text
#  distribution_key  :string
#  entity_id         :integer(4)       not null
#  id                :integer(4)       not null, primary key
#  lock_version      :integer(4)       default(0), not null
#  monthly_duration  :decimal(8, 2)    not null
#  name              :string
#  nature            :string
#  raw_hourly_amount :decimal(8, 2)    not null
#  reference_name    :string
#  salaried          :boolean          default(FALSE), not null
#  started_at        :datetime         not null
#  stopped_at        :datetime
#  updated_at        :datetime         not null
#  updater_id        :integer(4)
#
class WorkerContract < ApplicationRecord
  include Customizable
  include Attachable
  enumerize :distribution_key, in: %i[gross_margin percentage], default: :gross_margin, predicates: true
  belongs_to :entity, class_name: 'Entity', inverse_of: :worker_contracts
  belongs_to :contract_nature, primary_key: :reference_name, class_name: 'MasterDoerContract', foreign_key: :reference_name
  has_many :economic_cash_indicators, class_name: 'EconomicCashIndicator', inverse_of: :worker_contract, dependent: :destroy
  has_many :distributions, class_name: 'WorkerContractDistribution', dependent: :destroy, inverse_of: :worker_contract
  enumerize :nature, in: %i[permanent_worker temporary_worker external_staff], default: :permanent_worker, predicates: true
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :contract_end, :name, :reference_name, length: { maximum: 500 }, allow_blank: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :monthly_duration, :raw_hourly_amount, presence: true, numericality: { greater_than: -1_000_000, less_than: 1_000_000 }
  validates :salaried, inclusion: { in: [true, false] }
  validates :started_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }
  validates :stopped_at, timeliness: { on_or_after: ->(worker_contract) { worker_contract.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :entity, presence: true
  # ]VALIDATORS]
  accepts_nested_attributes_for :distributions, reject_if: :all_blank, allow_destroy: true

  scope :of_nature, ->(nature) { where(nature: nature) }

  scope :active_at, ->(started_at)  { where('started_at <= ? AND (stopped_at IS NULL OR stopped_at >= ?)', started_at, started_at) }

  scope :in_month, ->(month) { where('EXTRACT(MONTH FROM started_at) <= ? AND (stopped_at IS NULL OR EXTRACT(MONTH FROM stopped_at) >= ?)', month, month) }
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
    self.contract_end ||= 'determined' if stopped_at
    self.distribution_key ||= :gross_margin
  end

  after_save do
    if distributions.any?
      total = distributions.sum(:affectation_percentage)
      if total != 100
        sum = 0
        distributions.each do |distribution|
          percentage = (distribution.affectation_percentage * 100.0 / total).round(2)
          sum += percentage
          distribution.update_column(:affectation_percentage, percentage)
        end
        if sum != 100
          distribution = distributions.last
          distribution.update_column(:affectation_percentage, distribution.affectation_percentage + (100 - sum))
        end
      end
    else
      distributions.clear
    end
    update_intervention_costs
    update_economic_cash_indicators
  end

  def month_duration
    if stopped_at && (stopped_at - started_at) < 1.year
      ((stopped_at - started_at).to_f / ( 3600 * 24 * 30 )).round(2)
    else
      12
    end
  end

  # update intervention where worker has a contract before intervention
  def update_intervention_costs
    intervention_ids_to_update = []
    if entity.worker
      intervention_ids_to_update << entity.worker.interventions.where('started_at >= ?', started_at)&.pluck(:id)
    end
    int_ids = intervention_ids_to_update.flatten.compact.uniq
    UpdateInterventionCostingsJob.perform_later(int_ids, to_reload: true) if int_ids.any?
  end

  # compute and save worker_contract for each cash movement in economic_cash_indicators
  def update_economic_cash_indicators
    self.economic_cash_indicators.destroy_all

    # build month period from contract dates
    res = started_at.to_time
    stop = stopped_at&.to_time || (Time.now + 1.years).to_time
    periods = []

    while res < stop
      campaign = Campaign.of(res.year)
      if res.end_of_month <= stop
        periods << { campaign_id: campaign.id, used_on: res.end_of_month.to_date, month_coef_for_amount: 1.0 }
      else
        month_coef = (stop.day - res.day).to_d / 30.0
        periods << { campaign_id: campaign.id, used_on: stop.to_date, month_coef_for_amount: month_coef.round(2) }
      end
      res += 1.month
    end

    # build default attributes
    default_attributes = { context: 'Salaires',
                           context_color: 'Chocolate',
                           direction: 'expense',
                           origin: 'contract',
                           nature: self.nature }

    # create cash movement for each year repetition with used and paid
    periods.each do |period|
      gap_used_on = period[:used_on]
      gap_paid_on = period[:used_on]
      salary_amount = (cost(period: :month, mode: :charged) * period[:month_coef_for_amount]).round(2)
      period_attributes = { campaign_id: period[:campaign_id],
                            used_on: gap_used_on,
                            paid_on: gap_paid_on,
                            amount: salary_amount,
                            pretax_amount: salary_amount }
      attrs = default_attributes.merge(period_attributes)
      self.economic_cash_indicators.create!(attrs)
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

    def annual_cost(nature, campaign, permanent_salaried = true, activity = nil)
      cost = 0.0
      in_year(campaign.harvest_year).of_nature(nature).each do |contract|
        next if contract.salaried != permanent_salaried && contract.nature == 'permanent_worker'

        if activity
          ratio = contract.distributions.where(main_activity: activity).sum(:affectation_percentage)
          contract_value = ( ratio / 100 ) * contract.cost(period: :year, mode: :charged)
        else
          contract_value = contract.cost(period: :year, mode: :charged)
        end
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
