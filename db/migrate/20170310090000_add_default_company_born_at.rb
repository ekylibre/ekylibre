class AddDefaultCompanyBornAt < ActiveRecord::Migration
  def up

    # first_financial_year = FinancialYear.order(:started_on).limit(1).first
    first_financial_year_started_on = select_value("SELECT started_on FROM financial_years ORDER BY started_on LIMIT 1")

    if first_financial_year_started_on.nil?

      execute "UPDATE entities " \
              "SET born_at = '2008-01-01 00:00:00' " \
              "WHERE of_company = TRUE " \
              "AND born_at IS NULL"
    else

      execute "UPDATE entities " \
              "SET born_at = '#{first_financial_year_started_on}' " \
              "WHERE of_company = TRUE " \
              "AND born_at IS NULL"
    end
  end
end
