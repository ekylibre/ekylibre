module Printers
  class ShortBalanceSheetPrinter < BalanceSheetPrinter

    def compute_dataset
      dataset = []
      document_scope = :balance_sheet
      current_compute = AccountancyComputation.new(@financial_year)
      previous_compute = AccountancyComputation.new(@financial_year.previous) if @financial_year.previous

      current_raw_total_actif = 0.0
      current_depreciations_total_actif = 0.0
      current_net_total_actif = 0.0
      previous_net_total_actif = 0.0

      current_net_total_passif = 0.0
      previous_net_total_passif = 0.0

      g = HashWithIndifferentAccess.new
      g[:items] = []
      items = [[0, :unsubcribed_capital, :capitals_values],
               [1, :incorporeal_assets_total, :capitals_emissions],
               [1, :corporeal_assets_total, :reevaluation_gaps],
               [1, :alive_corporeal_assets_total, :capitals_liability_reserves],
               [1, :financial_assets_total, :capitals_anew_reports],
               [1, :long_cycle_alive_products_total, :capitals_profit_or_loss],
               [1, :short_cycle_alive_products_total, :capitals_investment_subsidies],
               [1, :stocks_supply, :capitals_risk_and_charges_provisions_total],
               [1, :stocks_total_products, :debts_loans_total],
               [0, :entities_advance_giveables, :others_debts_advance_receivables],
               [1, :entities_client_total, :others_debts_supplier_receivables],
               [0, :entities_state_receivables, :others_debts_state_debts],
               [1, :entities_associate_receivables, :debts_associate_total],
               [1, :entities_other_receivables, :others_debts_social_debts],
               [1, :entities_investment_security, :others_debts_total],
               [0, :entities_reserve, :debts_cashe_debts_total],
               [0, :entities_advance_charges, :others_debts_advance_products],
               [0, :entities_assets_gaps, :others_debts_liabilities_gaps]
              ]
      items.each do |item|
        i = HashWithIndifferentAccess.new
        i[:actif_name] = item[1].tl
        i[:passif_name] = item[2].tl
        i[:current_actif_raw_value] = ''
        i[:current_actif_variations] = ''
        i[:current_passif_net_value] = current_compute.sum_entry_items_by_line(document_scope, item[2])
        current_net_total_passif += i[:current_passif_net_value]

        if item[0].to_i == 1
          i[:current_actif_raw_value] = current_compute.sum_entry_items_by_line(document_scope, (item[1].to_s + "_raw").to_sym)
          current_raw_total_actif += i[:current_actif_raw_value]
          i[:current_actif_variations] = current_compute.sum_entry_items_by_line(document_scope, (item[1].to_s + "_depreciations").to_sym)
          current_depreciations_total_actif += i[:current_actif_variations]
          i[:current_actif_net_value] = current_compute.sum_entry_items_by_line(document_scope, (item[1].to_s + "_net").to_sym)
        elsif item[0].to_i == 0
          i[:current_actif_net_value] = current_compute.sum_entry_items_by_line(document_scope, item[1])
          current_raw_total_actif += i[:current_actif_net_value]
        end
        current_net_total_actif += i[:current_actif_net_value]

        i[:previous_actif_net_value] = ''
        i[:previous_passif_net_value] = ''
        if @financial_year.previous
          if item[0].to_i == 1
            i[:previous_actif_net_value] = previous_compute.sum_entry_items_by_line(document_scope, (item[1].to_s + "_net").to_sym)
          elsif item[0].to_i == 0
            i[:previous_actif_net_value] = previous_compute.sum_entry_items_by_line(document_scope, item[1])
          end
          previous_net_total_actif += i[:previous_actif_net_value]
          i[:previous_passif_net_value] = previous_compute.sum_entry_items_by_line(document_scope, item[2])
          previous_net_total_passif += i[:previous_passif_net_value]
        end
        g[:items] << i
      end

      g[:sum_actif_name] = :active_totals.tl
      g[:total_current_actif_raw_value] = current_raw_total_actif.round(2)
      g[:total_current_actif_variations] = current_depreciations_total_actif.round(2)
      g[:total_current_actif_net_value] = current_net_total_actif.round(2)
      g[:total_previous_actif_net_value] = previous_net_total_actif.round(2)
      g[:sum_passif_name] = :passive_totals.tl
      g[:total_current_passif_net_value] = current_net_total_passif.round(2)
      g[:total_previous_passif_net_value] = previous_net_total_passif.round(2)

      dataset << g

      data_filters = []
      data_filters << :currency.tl + " : " + @financial_year.currency
      data_filters <<  :accounting_system.tl + " : " + Nomen::AccountingSystem.find(@accounting_system).human_name

      dataset << data_filters
      dataset.compact
    end

    def run_pdf
      dataset = compute_dataset
      data_filters = dataset.pop

      generate_report(@template_path) do |r|

        e = Entity.of_company
        company_name = e.full_name
        company_address = e.default_mail_address&.coordinate

        started_on = @financial_year.started_on
        stopped_on = @financial_year.stopped_on

        r.add_field 'COMPANY_ADDRESS', company_address
        r.add_field 'DOCUMENT_NAME', document_name
        r.add_field 'FILE_NAME', key
        r.add_field 'PERIOD', I18n.translate('labels.from_to_date', from: started_on.l, to: stopped_on.l)
        r.add_field 'DATE', Date.today.l
        r.add_field 'STARTED_ON', started_on.to_date.l
        r.add_field 'N', stopped_on.to_date.l
        r.add_field 'N_1', @financial_year.previous ? @financial_year.previous.stopped_on.to_date.l : 'N-1'
        r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
        r.add_field 'DATA_FILTERS', data_filters * ' | '

        r.add_section('Section1', dataset) do |s|
          s.add_table('Tableau1', :items, header: false) do |t|
            t.add_column(:actif_name) { |item| item[:actif_name] }
            t.add_column(:c_a_r_v) { |item| number_to_accountancy(item[:current_actif_raw_value]) }
            t.add_column(:c_a_v) { |item| number_to_accountancy(item[:current_actif_variations]) }
            t.add_column(:c_a_n_v) { |item| number_to_accountancy(item[:current_actif_net_value]) }
            t.add_column(:p_a_n_v) { |item| number_to_accountancy(item[:previous_actif_net_value]) }
            t.add_column(:passif_name) { |item| item[:passif_name] }
            t.add_column(:c_p_n_v) { |item| number_to_accountancy(item[:current_passif_net_value]) }
            t.add_column(:p_p_n_v) { |item| number_to_accountancy(item[:previous_passif_net_value]) }
          end
          s.add_field(:sum_actif_name, :sum_actif_name)
          s.add_field(:sum_passif_name, :sum_passif_name)
          s.add_field(:t_a_c_r_v) {|d| number_to_accountancy(d[:total_current_actif_raw_value])}
          s.add_field(:t_a_c_v_v) {|d| number_to_accountancy(d[:total_current_actif_variations])}
          s.add_field(:t_a_c_n_v) {|d| number_to_accountancy(d[:total_current_actif_net_value])}
          s.add_field(:t_p_c_n_v) {|d| number_to_accountancy(d[:total_current_passif_net_value])}
          s.add_field(:t_a_p_n_v) {|d| number_to_accountancy(d[:total_previous_actif_net_value])}
          s.add_field(:t_p_p_n_v) {|d| number_to_accountancy(d[:total_previous_passif_net_value])}
        end
      end
    end
  end
end
