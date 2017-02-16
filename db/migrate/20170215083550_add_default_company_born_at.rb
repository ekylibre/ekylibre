class AddDefaultCompanyBornAt < ActiveRecord::Migration
  def up

    oldest_financial_year = FinancialYear.order(:started_on).limit(1).first

    if oldest_financial_year.nil?
    
      execute "UPDATE entities " \
              "SET born_at = '2008-01-01 00:00:00' " \
              "WHERE of_company = TRUE " \
              "AND born_at IS NULL"  
    else

      execute "UPDATE entities " \
              "SET born_at = '#{oldest_financial_year.started_on}' " \
              "WHERE of_company = TRUE " \
              "AND born_at IS NULL"  
    end 
  end
end
