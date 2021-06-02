class AddIsacomptaFieldsToFinancialYearExchanges < ActiveRecord::Migration[5.0]
  def change
    add_column :financial_year_exchanges, :format, :string, null: false, default: 'ekyagri'
    add_column :financial_year_exchanges, :transmit_isacompta_analytic_codes, :boolean, default: false
  end
end
