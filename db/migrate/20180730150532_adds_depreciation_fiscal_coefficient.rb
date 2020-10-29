class AddsDepreciationFiscalCoefficient < ActiveRecord::Migration
  def change
    add_column :fixed_assets, :depreciation_fiscal_coefficient, :decimal
  end
end
