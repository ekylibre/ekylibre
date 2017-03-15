class AddNotNullContraintIfCompanyEntity < ActiveRecord::Migration
  def change
    execute 'ALTER TABLE entities ADD CONSTRAINT company_born_at_not_null CHECK (( of_company = TRUE AND born_at IS NOT NULL) OR (of_company = FALSE))'
  end
end
