class AddsDepreciationFiscalCoefficient < ActiveRecord::Migration[4.2]
  def change
    add_column :fixed_assets, :depreciation_fiscal_coefficient, :decimal
  end
end
