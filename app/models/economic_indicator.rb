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
# == Materialized View: economic_indicators
#
#
class EconomicIndicator < ApplicationRecord

  belongs_to :campaign
  belongs_to :activity
  belongs_to :output_variant, class_name: 'ProductNatureVariant'
  belongs_to :output_variant_unit, class_name: 'Unit'

  scope :of_campaign, ->(campaign) { where(campaign: campaign)}
  scope :of_activity, ->(activity) { where(activity: activity)}
  scope :of_main_product, -> { where.not(output_variant_id: nil)}
  scope :of_indicators, ->(indicators) { where(economic_indicator: indicators)}

  class << self
    def refresh
      Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
    end

    def activity_simulator(target_activity, campaign)
      items = {}.with_indifferent_access
      main_indicator = EconomicIndicator.of_campaign(campaign).of_activity(target_activity).of_main_product
      indicators = EconomicIndicator.of_campaign(campaign).of_activity(target_activity)
      if main_indicator.any? && indicators.any?
        # set key for the moment
        key = :gross_margin
        # compute ratio for activity (indirects) loans, depreciations and salary
        ratio = main_indicator.first.generate_ratio(target_activity, key = key)
        # build fixed_direct_charges (worker, loan and fixed asset directly set on target_activity)
        fixed_direct_charges = 0.0
        options = { activity_id: target_activity.id }
        # direct charge on budget
        fixed_direct_charges += indicators.find_by(economic_indicator: 'fixed_direct_charge')&.amount.to_f.round(2)
        # loan repayments charge amount && depreciations charges
        fixed_direct_charges += EconomicIndicator.loan_repayments_charges_amount(campaign, options).to_f.round(2)
        fixed_direct_charges += EconomicIndicator.depreciations_charges_amount(campaign, options).to_f.round(2)
        # worker contracts directly on activities
        fixed_direct_charges += WorkerContract.where(distribution_key: 'percentage').annual_cost(%w[permanent_worker temporary_worker external_staff], campaign, true, target_activity).to_f.round(2)
        fixed_direct_charges += WorkerContract.where(distribution_key: 'percentage').annual_cost(%w[permanent_worker], campaign, false, target_activity).to_f.round(2)

        # build items
        items[:total_area] = main_indicator.first.activity_size_value.to_f.round(2)
        items[:area_unit] = main_indicator.first.activity_size_unit
        items[:main_product_name] = main_indicator.first.output_variant.name
        items[:main_product_variety] = ActivityBudget.find_by(activity_id: target_activity.id, campaign_id: campaign.id)&.variety_output
        items[:main_product_yield] = ActivityBudget.find_by(activity_id: target_activity.id, campaign_id: campaign.id)&.estimate_yield.to_f.round(2)
        items[:main_product_yield_unit_id] = main_indicator.first.output_variant_unit_id
        # PLANNED VALUES
        items[:proportional_main_product_products] = main_indicator.first.amount.to_f.round(2) || 0.0
        items[:fixed_direct_products] = indicators.find_by(economic_indicator: 'other_direct_product')&.amount.to_f.round(2) || 0.0
        items[:proportional_direct_charges] = indicators.find_by(economic_indicator: 'proportional_direct_charge')&.amount.to_f.round(2) || 0.0
        items[:fixed_direct_charges] = fixed_direct_charges
        items[:gross_margin] = EconomicIndicator.activity_gross_margin_amount(target_activity, campaign).to_f.round(2) || 0.0
        items[:activity_indirect_products] = { activity_value: (EconomicIndicator.activity_indirect_amount(campaign, :global_indirect_product).to_f.round(2) || 0.0) * ratio, activity_ratio: ratio }
        items[:activity_cash_provisions] = { activity_value: 0.0, activity_ratio: ratio }
        items[:activity_indirect_charges] = { activity_value: (EconomicIndicator.activity_indirect_amount(campaign, :global_indirect_charge).to_f.round(2) || 0.0) * ratio, activity_ratio: ratio }
        items[:activity_employees_wages] = { activity_value: ((WorkerContract.where.not(distribution_key: 'percentage').annual_cost(%w[permanent_worker temporary_worker external_staff], campaign, true).to_f.round(2) || 0.0) * ratio), activity_ratio: ratio }
        items[:activity_depreciations_charges] = { activity_value: ((EconomicIndicator.depreciations_charges_amount(campaign).to_f.round(2) || 0.0) * ratio), activity_ratio: ratio }
        items[:activity_loans_charges] = { activity_value: ((EconomicIndicator.loan_repayments_charges_amount(campaign).to_f.round(2) || 0.0) * ratio), activity_ratio: ratio }
        items[:activity_farmer_wages] = { activity_value: ((WorkerContract.where.not(distribution_key: 'percentage').annual_cost(%w[permanent_worker], campaign, false).to_f.round(2) || 0.0) * ratio), activity_ratio: ratio }
        # REALISED VALUES
        items[:real_proportional_main_product_products] = main_indicator.first.compute_realised_element(:main_direct_products)
        items[:real_fixed_direct_products] = main_indicator.first.compute_realised_element(:fixed_direct_products)
        items[:real_proportional_direct_charges] = main_indicator.first.compute_realised_element(:proportional_direct_charges)
        items[:real_fixed_direct_charges] = main_indicator.first.compute_realised_element(:fixed_direct_charges)
        items[:real_gross_margin] = (items[:real_proportional_main_product_products] + items[:real_fixed_direct_products]) - (items[:real_proportional_direct_charges] + items[:real_fixed_direct_charges])
        items[:real_activity_indirect_products] = { activity_value: main_indicator.first.compute_realised_element(:indirect_products, :all) * ratio, activity_ratio: ratio }
        items[:real_activity_cash_provisions] = { activity_value: main_indicator.first.compute_realised_element(:cash_provisions, :all) * ratio, activity_ratio: ratio }
        items[:real_activity_indirect_charges] = { activity_value: main_indicator.first.compute_realised_element(:indirect_charges, :all) * ratio, activity_ratio: ratio }
        items[:real_activity_employees_wages] = { activity_value: main_indicator.first.compute_realised_element(:employees_wages, :all) * ratio, activity_ratio: ratio }
        items[:real_activity_depreciations_charges] = { activity_value: main_indicator.first.compute_realised_element(:depreciations_charges, :all) * ratio, activity_ratio: ratio }
        items[:real_activity_loans_charges] = { activity_value: main_indicator.first.compute_realised_element(:loans_charges, :all) * ratio, activity_ratio: ratio }
        items[:real_activity_farmer_wages] = { activity_value: main_indicator.first.compute_realised_element(:farmer_wages, :all) * ratio, activity_ratio: ratio }
        items
      else
        nil
      end
    end

    def indirect_exploitation_charges_simulator(campaign)
      items = {}.with_indifferent_access
      global_indirect_product = EconomicIndicator.of_campaign(campaign).where(economic_indicator: 'global_indirect_product')
      global_indirect_charge = EconomicIndicator.of_campaign(campaign).where(economic_indicator: 'global_indirect_charge')
      if global_indirect_charge.any?
        items[:annual_farmer_wages] = WorkerContract.annual_cost(%w[permanent_worker], campaign, false).to_f.round(2) || 0.0
        items[:annual_employees_wages] = WorkerContract.annual_cost(%w[permanent_worker temporary_worker external_staff], campaign, true).to_f.round(2) || 0.0
        items[:annual_fixed_charges] = global_indirect_charge.sum(:amount).to_f.round(2) || 0.0
        items[:annual_cash_provisions] = 0.0
        items[:annual_fixed_products] = global_indirect_product&.sum(:amount)&.to_f&.round(2) || 0.0
        items[:annual_depreciations_charges] = EconomicIndicator.depreciations_charges_amount(campaign)&.to_f&.round(2) || 0.0
        items[:annual_loans_charges] = EconomicIndicator.loan_repayments_charges_amount(campaign)&.to_f&.round(2) || 0.0
        items[:currency] = Onoma::Currency.find(Preference[:currency]).symbol
        items.to_struct
      else
        nil
      end
    end

    # return the value of all indirect product (ponderate with distribution_key)
    # for all auxiliary activities in a campaign
    # indicator is (global_indirect_product global_indirect_charge)
    def activity_indirect_amount(campaign, indicator)
      activity_indirect_element_amount = 0.0
      of_campaign(campaign).where(economic_indicator: indicator.to_s).each do |agip|
        activity_indirect_element_amount += agip.amount.round(2) if agip.amount
      end
      activity_indirect_element_amount
    end

    def activity_gross_margin_amount(activity, campaign)
      direct_product_amount = EconomicIndicator.where(activity: activity, campaign: campaign, economic_indicator: %w[main_direct_product other_direct_product]).sum(:amount)
      direct_charge_amount = EconomicIndicator.where(activity: activity, campaign: campaign, economic_indicator: %w[proportional_direct_charge fixed_direct_charge]).sum(:amount)
      direct_product_amount - direct_charge_amount
    end

    def all_main_activity_gross_margin_amount(campaign)
      # auxiliary activity don't have this indicator don't need to filter activity before
      direct_product_amount = EconomicIndicator.where(campaign: campaign, economic_indicator: %w[main_direct_product other_direct_product]).sum(:amount)
      direct_charge_amount = EconomicIndicator.where(campaign: campaign, economic_indicator: %w[proportional_direct_charge fixed_direct_charge]).sum(:amount)
      direct_product_amount - direct_charge_amount
    end

    def loan_repayments(campaign, options = {})
      if options.key?(:activity_id)
        act = options[:activity_id]
      else
        act = nil
      end
      repayments = LoanRepayment.includes(:loan).where(loans: { activity_id: act }, due_on: Date.civil(campaign.harvest_year, 1, 1)..Date.civil(campaign.harvest_year, 12, 31))
      repayments = repayments.where('due_on <= ?', options[:on]) if options.key?(:on)
      repayments
    end

    def loan_repayments_amount(campaign, options = {})
      loan_repayments(campaign, options).sum(:amount)
    end

    def loan_repayments_charges_amount(campaign, options = {})
      loan_repayments(campaign, options).sum(:interest_amount) + loan_repayments(campaign, options).sum(:insurance_amount)
    end

    def depreciations(campaign, options = {})
      if options.key?(:activity_id)
        act = options[:activity_id]
      else
        act = nil
      end
      FixedAssetDepreciation.includes(:fixed_asset).where(fixed_assets: { activity_id: act }).from_to(Date.civil(campaign.harvest_year, 1, 1), Date.civil(campaign.harvest_year, 12, 31))
    end

    def depreciations_charges_amount(campaign, options = {})
      depreciations(campaign, options).sum(:amount)
    end

  end

  def readonly?
    true
  end

  # distribution_key is (gross_margin percentage equipment_intervention_duration)
  # distribution_key is set on activity
  # return ratio for a target activity related to distribution_key on considered aux_activity
  def generate_ratio(target_activity, key = nil)
    ratio = 0.0
    key ||= self.activity.distribution_key.to_sym
    if key == :gross_margin
      gross_margin = EconomicIndicator.activity_gross_margin_amount(target_activity, self.campaign)
      all_gross_margin = EconomicIndicator.all_main_activity_gross_margin_amount(self.campaign)
      ratio = (gross_margin.to_f / all_gross_margin.to_f.abs).round(2)
    elsif key == :percentage && self.activity.auxiliary?
      distribution = self.activity.distributions.find_by(main_activity: target_activity)
      ratio = distribution.affectation_percentage.round(2) if distribution
    end
    if ratio.nil? || ratio.blank?
      ratio = 0.0
    elsif ratio > 1.0
      ratio = 1.0
    elsif ratio < 0.0
      ratio = 0.0
    else
      ratio.round(2)
    end
  end

  # get accountancy element
  # on activity periods
  # where activity_budget_id present on jei
  # with accountancy mandatary indicator
  def compute_realised_element(accountancy_indicator = nil, mode = :activity)
    if mode == :activity
      current_compute = EconomicAccountancyComputation.new(self.campaign, self.activity)
    elsif mode == :all
      current_compute = EconomicAccountancyComputation.new(self.campaign)
    end
    current_compute.sum_entry_items_by_line(accountancy_indicator)
  end

end
