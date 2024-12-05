# frozen_string_literal: true

module FarmProfiles
  class AccountancyInformations

    def initialize(harvest_year)
      @campaign = Campaign.of(harvest_year)
      @started_on = Date.new(@campaign.harvest_year, 1, 1)
      @stopped_on = Date.new(@campaign.harvest_year, 12, 31)
      @financial_year = FinancialYear.closest(@stopped_on)
      @base_compute = AccountancyComputation.new(@financial_year)
    end

    def global_ratio_informations
      # Products
      exercice_production = @base_compute.sum_entry_items_by_line(:ratio, :exercice_production)
      # commercial_margin
      commercial_margin = @base_compute.sum_entry_items_by_line(:ratio, :commercial_margin)
      # production_purchases
      production_purchases = @base_compute.sum_entry_items_by_line(:ratio, :production_purchases)
      # production_others_charges
      production_others_charges = @base_compute.sum_entry_items_by_line(:ratio, :production_others_charges)
      # added value
      added_value = (exercice_production + commercial_margin) - (production_purchases + production_others_charges)
      # subsidies
      subsidies = @base_compute.sum_entry_items_by_line(:ratio, :subsidies)
      # taxes_and_wages
      taxes_and_wages = @base_compute.sum_entry_items_by_line(:ratio, :taxes_and_wages)
      # operating_margin
      operating_margin = added_value + subsidies - taxes_and_wages

      {
        exercice_production: { label: :exercice_production.tl(financial_year: @financial_year.name), value: exercice_production },
        commercial_margin: { label: :commercial_margin.tl(financial_year: @financial_year.name), value: commercial_margin },
        production_purchases: { label: :production_purchases.tl(financial_year: @financial_year.name), value: production_purchases },
        production_others_charges: { label: :production_others_charges.tl(financial_year: @financial_year.name), value: production_others_charges },
        added_value: { label: :added_value.tl(financial_year: @financial_year.name), value: added_value },
        subsidies: { label: :subsidies.tl(financial_year: @financial_year.name), value: subsidies },
        taxes_and_wages: { label: :taxes_and_wages.tl(financial_year: @financial_year.name), value: taxes_and_wages },
        operating_margin: { label: :operating_margin.tl(financial_year: @financial_year.name), value: operating_margin }
      }
    end

    def accountancy_informations
      acc_hash = {}
      acc_hash[:products] = { label: :products.tl(financial_year: @financial_year.name), value: @base_compute.sum_entry_items_by_line(:profit_and_loss_statement, :products_subtotal) }
      acc_hash[:charges] = { label: :charges.tl(financial_year: @financial_year.name), value: @base_compute.sum_entry_items_by_line(:profit_and_loss_statement, :charges_subtotal) }
      %i[exploitation financial exceptional exercice].each do |r|
        item = "#{r}_result"
        result = @base_compute.sum_entry_items_by_line(:profit_and_loss_statement, item.to_sym)
        acc_hash[item.to_s] = { label: item.to_sym.tl(financial_year: @financial_year.name), value: result }
      end
      acc_hash
    end

    def economic_informations
      act_eco = []
      Activity.of_campaign(@campaign).each do |act|
        res = EconomicIndicator.activity_simulator(act, @campaign)
        act_eco << res
      end
      act_eco.compact
    end

    #
    # unit method indicator
    #
  end
end
