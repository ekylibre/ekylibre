# This object allow printing the general ledger
module Printers
  class BalanceSheetPrinter < PrinterBase
    include ApplicationHelper

    class << self
      # TODO move this elsewhere when refactoring the Document Management System
      def build_key(financial_year:)
        financial_year.code
      end
    end

    def initialize(*_args, financial_year:, template:, **_options)
      super(template: template)
      @financial_year = financial_year
      @accounting_system = Preference[:accounting_system].to_sym
      @current_compute = AccountancyComputation.new(@financial_year)
      @previous_compute = AccountancyComputation.new(@financial_year.previous) if @financial_year.previous
      @document_scope = :balance_sheet
    end

    def key
      self.class.build_key(financial_year: @financial_year)
    end

    def document_name
      "#{@template.nature.human_name} (#{@financial_year.code})"
    end

    def compute_dataset
      dataset = []

      ## ACTIF
      actif = []
      current_net_total_actif = 0.0
      previous_net_total_actif = 0.0

      base_active = [
                    [:unsubcribed_capital, false, [:unsubcribed_capital]], # unsubcribed_capital - 109
                    [:incorporeal_assets, true, [:incorporeal_assets_creation_costs, :incorporeal_assets_others, :incorporeal_assets_advances]], # incorporeal_assets - 201...
                    [:corporeal_assets, true, [:corporeal_assets_land_parcels, :corporeal_assets_settlements,
                             :corporeal_assets_enhancement, :corporeal_assets_buildings,
                             :corporeal_assets_equipments, :corporeal_assets_others,
                             :corporeal_assets_in_progress, :corporeal_assets_advances]],
                    [:financial_assets, true, [:financial_assets_participations, :financial_assets_participations_debts,
                             :financial_assets_others]],

                    ]

      base_bottom_active = [
                            [:entities, false, [:entities_advance_giveables, :entities_client_receivables,
                             :entities_others_clients, :entities_state_receivables,
                             :entities_associate_receivables, :entities_other_receivables,
                             :entities_investment_security, :entities_reserve,
                             :entities_advance_charges, :entities_assets_gaps]]
      ]

      base_active.each do |group_item, is_multi_items, items|
        g = generate_items(group_item, is_multi_items, items)
        current_net_total_actif += g[:current_net_total]
        previous_net_total_actif += g[:previous_net_total] if @financial_year.previous
        actif << g
      end

      # PCGA - alive corporeal_assets, short & long_cycle_alive_products, stocks
      if @accounting_system == :fr_pcga
        pcga_alive_active = [
                        [:alive_corporeal_assets, true, [:alive_corporeal_assets_adult_animals, :alive_corporeal_assets_young_animals,
                                 :alive_corporeal_assets_service_animals, :alive_corporeal_assets_perennial_plants,
                                 :alive_corporeal_assets_others, :alive_corporeal_assets_in_progress,
                                 :alive_corporeal_assets_advances]],
                        [:long_cycle_alive_products, true, [:long_cycle_alive_products_animals, :long_cycle_alive_products_plant_advance,
                                 :long_cycle_alive_products_plant_in_ground, :long_cycle_alive_products_wine,
                                 :long_cycle_alive_products_others]],
                        [:short_cycle_alive_products, true, [:short_cycle_alive_products_animals, :short_cycle_alive_products_plant_advance,
                                 :short_cycle_alive_products_plant_in_ground, :short_cycle_alive_products_others]],
                        [:stocks, true, [:stocks_supply, :stocks_others_products, :stocks_end_products]],

        ]

        pcga_alive_active.each do |group_item, is_multi_items, items|
          g = generate_items(group_item, is_multi_items, items)
          current_net_total_actif += g[:current_net_total]
          previous_net_total_actif += g[:previous_net_total] if @financial_year.previous
          actif << g
        end
      end

      # PCG82 - alive corporeal_assets, short & long_cycle_alive_products, stocks
      if @accounting_system == :fr_pcg82
        pcg82_stock_active = [
                        [:stocks, true, [:raw_matters, :stocks_supply_products, :stocks_supply_services, :stocks_middle_products, :stocks_end_products]]

        ]

        pcg82_stock_active.each do |group_item, is_multi_items, items|
          g = generate_items(group_item, is_multi_items, items)
          current_net_total_actif += g[:current_net_total]
          previous_net_total_actif += g[:previous_net_total] if @financial_year.previous
          actif << g
        end
      end

      base_bottom_active.each do |group_item, is_multi_items, items|
        g = generate_items(group_item, is_multi_items, items)
        current_net_total_actif += g[:current_net_total]
        previous_net_total_actif += g[:previous_net_total] if @financial_year.previous
        actif << g
      end

      # Total Actif
      g10 = HashWithIndifferentAccess.new
      g10[:group_name] = :total_actif.tl
      g10[:items] = []
      g10[:sum_name] = ''
      g10[:current_raw_total] = ''
      g10[:current_variations_total] = ''
      g10[:current_net_total] = current_net_total_actif
      if @financial_year.previous
        g10[:previous_raw_total] = ''
        g10[:previous_variations_total] = ''
        g10[:previous_net_total] = previous_net_total_actif
      end
      actif << g10

      dataset << actif

      passif = []
      current_net_total_passif = 0.0
      previous_net_total_passif = 0.0

      base_passive = [
                      [:capitals, false, [:capitals_values, :capitals_emissions, :reevaluation_gaps,
                               :capitals_liability_reserves, :capitals_anew_reports,
                               :capitals_profit_or_loss, :capitals_investment_subsidies,
                               :capitals_derogatory_depreciations, :capitals_mandatory_provisions,
                               :capitals_risk_and_charges_provisions]],
                      [:debts, false, [:debts_land_parcel_loans, :debts_others_loans,
                               :debts_associate_locked_debts, :debts_cashe_debts,
                               :debts_other_financial_debts]],
                      [:others_debts, false, [:others_debts_advance_receivables, :others_debts_supplier_receivables,
                               :others_debts_state_debts, :others_debts_social_debts,
                               :others_debts_associate_debts, :others_debts_fixed_asset_debts,
                               :others_debts_others, :others_debts_advance_products,
                               :others_debts_liabilities_gaps]]
      ]


      base_passive.each do |group_item, is_multi_items, items|
        g = generate_items(group_item, is_multi_items, items)
        current_net_total_passif += g[:current_net_total]
        previous_net_total_passif += g[:previous_net_total] if @financial_year.previous
        passif << g
      end

      # Total Passif
      h = HashWithIndifferentAccess.new
      h[:group_name] = :total_passif.tl
      h[:items] = []
      h[:sum_name] = ''
      h[:current_net_total] = current_net_total_passif
      h[:previous_net_total] = previous_net_total_passif if @financial_year.previous
      passif << h

      dataset << passif

      dataset.compact
    end

    def generate_items(group_item, is_multi_items, items)
      #TODO
      g1 = HashWithIndifferentAccess.new
      g1[:group_name] = group_item.tl
      g1[:items] = []
      items.each do |item|
        i = HashWithIndifferentAccess.new
        i[:name] = item.to_s.tl
        i[:current_raw_value] = @current_compute.sum_entry_items_by_line(@document_scope, item)
        i[:current_variations] = (is_multi_items == true ? @current_compute.sum_entry_items_by_line(@document_scope, (item.to_s + "_depreciations").to_sym) : '')
        if is_multi_items == true
          i[:current_net_value] = (i[:current_raw_value].to_d - i[:current_variations].to_d).round(2)
        else
          i[:current_net_value] = i[:current_raw_value]
        end
        if @financial_year.previous
          i[:previous_raw_value] = @previous_compute.sum_entry_items_by_line(@document_scope, item)
          i[:previous_variations] = (is_multi_items == true ? @previous_compute.sum_entry_items_by_line(@document_scope, (item.to_s + "_depreciations").to_sym) : '')
          if is_multi_items == true
            i[:previous_net_value] = (i[:previous_raw_value].to_d - i[:previous_variations].to_d).round(2)
          else
            i[:previous_net_value] = i[:previous_raw_value]
          end
        end
        g1[:items] << i
        # puts g1.inspect.yellow
      end
      g1[:sum_name] = ""
      g1[:current_raw_total] = g1[:items].map { |h| h[:current_raw_value] }.sum
      if is_multi_items == true
        g1[:current_variations_total] = g1[:items].map { |h| h[:current_variations] }.sum
        g1[:current_net_total] = (g1[:current_raw_total].to_d - g1[:current_variations_total].to_d).round(2)
      else
        g1[:current_net_total] = g1[:current_raw_total]
      end
      if @financial_year.previous
        g1[:previous_raw_total] = g1[:items].map { |h| h[:previous_raw_value] }.sum
        if is_multi_items == true
          g1[:previous_variations_total] = g1[:items].map { |h| h[:previous_variations] }.sum
          g1[:previous_net_total] = (g1[:previous_raw_total].to_d - g1[:previous_variations_total].to_d).round(2)
        else
          g1[:previous_net_total] = g1[:previous_raw_total]
        end
      end
      g1
    end

    def run_pdf
      dataset = compute_dataset

      generate_report(@template_path) do |r|

        # build header
        e = Entity.of_company
        company_name = e.full_name
        company_address = e.default_mail_address&.coordinate

        # build filters
        data_filters = []
        data_filters <<  :accounting_system.tl + " : " + Nomen::AccountingSystem.find(@accounting_system).human_name

        # build started and stopped
        started_on = @financial_year.started_on
        stopped_on = @financial_year.stopped_on

        r.add_field 'COMPANY_ADDRESS', company_address
        r.add_field 'DOCUMENT_NAME', document_name
        r.add_field 'FILE_NAME', key
        r.add_field 'PERIOD', I18n.translate('labels.from_to_date', from: started_on.l, to: stopped_on.l)
        r.add_field 'DATE', Date.today.l
        r.add_field 'STARTED_ON', started_on.to_date.l
        r.add_field 'N', stopped_on.to_date.l
        r.add_field 'N_1', @financial_year.previous.stopped_on.to_date.l if @financial_year.previous
        r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
        r.add_field 'DATA_FILTERS', data_filters * ' | '

        r.add_section('Section1', dataset[0]) do |s|
          s.add_field(:group_name, :group_name)
          s.add_table('Tableau1', :items, header: true) do |t|
            t.add_column(:name) { |item| item[:name] }
            t.add_column(:current_raw_value) { |item| number_to_accountancy(item[:current_raw_value]) }
            t.add_column(:current_variations) { |item| number_to_accountancy(item[:current_variations]) }
            t.add_column(:current_net_value) { |item| number_to_accountancy(item[:current_net_value]) }
            t.add_column(:previous_raw_value) { |item| number_to_accountancy(item[:previous_raw_value]) }
            t.add_column(:previous_variations) { |item| number_to_accountancy(item[:previous_variations]) }
            t.add_column(:previous_net_value) { |item| number_to_accountancy(item[:previous_net_value]) }
          end
          s.add_field(:sum_name, :sum_name)
          s.add_field(:c_r_total) { |d| number_to_accountancy(d[:current_raw_total]) }
          s.add_field(:c_v_total) { |d| number_to_accountancy(d[:current_variations_total]) }
          s.add_field(:c_n_total) { |d| number_to_accountancy(d[:current_net_total]) }
          s.add_field(:p_r_total) { |d| number_to_accountancy(d[:previous_raw_total]) }
          s.add_field(:p_v_total) { |d| number_to_accountancy(d[:previous_variations_total]) }
          s.add_field(:p_n_total) { |d| number_to_accountancy(d[:previous_net_total]) }
        end

        r.add_section('Section2', dataset[1]) do |s|
          s.add_field(:group_name, :group_name)
          s.add_table('Tableau5', :items, header: true) do |t|
            t.add_column(:name) { |item| item[:name] }
            t.add_column(:current_raw_value) { |item| number_to_accountancy(item[:current_raw_value]) }
            t.add_column(:previous_raw_value) { |item| number_to_accountancy(item[:previous_raw_value]) }
          end
          s.add_field(:sum_name, :sum_name)
          s.add_field(:c_r_total) { |d| number_to_accountancy(d[:current_net_total]) }
          s.add_field(:p_r_total) { |d| number_to_accountancy(d[:previous_net_total]) }
        end
      end
    end
  end
end
