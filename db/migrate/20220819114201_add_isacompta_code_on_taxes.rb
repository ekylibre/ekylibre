class AddIsacomptaCodeOnTaxes < ActiveRecord::Migration[5.1]
  def change
    add_column :taxes, :collect_isacompta_code, :string
    add_column :taxes, :deduction_isacompta_code, :string
    add_column :taxes, :fixed_asset_deduction_isacompta_code, :string
    add_column :taxes, :fixed_asset_collect_isacompta_code, :string
  end
end
