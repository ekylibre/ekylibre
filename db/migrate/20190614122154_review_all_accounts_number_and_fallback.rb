# Migration generated with nomenclature migration #20180711093131
class ReviewAllAccountsNumberAndFallback < ActiveRecord::Migration[4.2]
  def up
    # Change item accounts#exceptionnal_charge_transfer_revenues with {:fr_pcga=>"797", :fr_pcg82=>"797", :name=>"exceptional_charge_transfer_revenues"}
    execute "UPDATE accounts SET centralizing_account_name='exceptional_charge_transfer_revenues' WHERE centralizing_account_name='exceptionnal_charge_transfer_revenues'"
    # Change item accounts#exceptionnal_depreciations_inputations_expenses with {:fr_pcga=>"687", :fr_pcg82=>"687", :name=>"exceptional_depreciations_inputations_expenses"}
    execute "UPDATE accounts SET centralizing_account_name='exceptional_depreciations_inputations_expenses' WHERE centralizing_account_name='exceptionnal_depreciations_inputations_expenses'"
    # Change item accounts#exceptionnal_incorporeal_asset_depreciation_revenues with {:fr_pcga=>"787", :fr_pcg82=>"787", :name=>"exceptional_depreciations_inputations_revenues"}
    execute "UPDATE accounts SET centralizing_account_name='exceptional_depreciations_inputations_revenues' WHERE centralizing_account_name='exceptionnal_incorporeal_asset_depreciation_revenues'"
  end

  def down
    # Reverse: Change item accounts#exceptionnal_incorporeal_asset_depreciation_revenues with {:fr_pcga=>"787", :fr_pcg82=>"787", :name=>"exceptional_depreciations_inputations_revenues"}
    execute "UPDATE accounts SET centralizing_account_name='exceptionnal_incorporeal_asset_depreciation_revenues' WHERE centralizing_account_name='exceptional_depreciations_inputations_revenues'"
    # Reverse: Change item accounts#exceptionnal_depreciations_inputations_expenses with {:fr_pcga=>"687", :fr_pcg82=>"687", :name=>"exceptional_depreciations_inputations_expenses"}
    execute "UPDATE accounts SET centralizing_account_name='exceptionnal_depreciations_inputations_expenses' WHERE centralizing_account_name='exceptional_depreciations_inputations_expenses'"
    # Reverse: Change item accounts#exceptionnal_charge_transfer_revenues with {:fr_pcga=>"797", :fr_pcg82=>"797", :name=>"exceptional_charge_transfer_revenues"}
    execute "UPDATE accounts SET centralizing_account_name='exceptionnal_charge_transfer_revenues' WHERE centralizing_account_name='exceptional_charge_transfer_revenues'"
  end
end
