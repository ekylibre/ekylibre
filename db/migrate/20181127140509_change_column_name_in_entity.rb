class ChangeColumnNameInEntity < ActiveRecord::Migration
  def change
    rename_column :entities, :financial_year_start_at, :first_financial_year_ends_at
  end
end
