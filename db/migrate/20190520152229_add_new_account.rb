# Migration generated with nomenclature migration #20190520072403
class AddNewAccount < ActiveRecord::Migration
  def up
    # Change item accounts#animals_making_expenses_expenses with {:name=>"animals_making_expenses", :fr_pcga=>"6054"}
    execute "UPDATE accounts SET centralizing_account_name='animals_making_expenses' WHERE centralizing_account_name='animals_making_expenses_expenses'"
    # Change item accounts#land_parcel_construction_depreciations_inputations_expenses with {:name=>"corporeal_depreciations_inputations_expenses", :fr_pcga=>"68112", :fr_pcg82=>"68112"}
    execute "UPDATE accounts SET centralizing_account_name='corporeal_depreciations_inputations_expenses' WHERE centralizing_account_name='land_parcel_construction_depreciations_inputations_expenses'"
    # Change item accounts#animals_depreciations_inputations_expenses with {:name=>"corporeal_depreciations_inputations_expenses_living_goods", :fr_pcga=>"68114"}
    execute "UPDATE accounts SET centralizing_account_name='corporeal_depreciations_inputations_expenses_living_goods' WHERE centralizing_account_name='animals_depreciations_inputations_expenses'"
    # Change item accounts#land_parcel_sell_revenues with {:name=>"tangible_fixed_assets_revenues_without_livestock", :fr_pcga=>"7752", :fr_pcg82=>"7752"}
    execute "UPDATE accounts SET centralizing_account_name='tangible_fixed_assets_revenues_without_livestock' WHERE centralizing_account_name='land_parcel_sell_revenues'"
  end

  def down
    # Reverse: Change item accounts#land_parcel_sell_revenues with {:name=>"tangible_fixed_assets_revenues_without_livestock", :fr_pcga=>"7752", :fr_pcg82=>"7752"}
    execute "UPDATE accounts SET centralizing_account_name='land_parcel_sell_revenues' WHERE centralizing_account_name='tangible_fixed_assets_revenues_without_livestock'"
    # Reverse: Change item accounts#animals_depreciations_inputations_expenses with {:name=>"corporeal_depreciations_inputations_expenses_living_goods", :fr_pcga=>"68114"}
    execute "UPDATE accounts SET centralizing_account_name='animals_depreciations_inputations_expenses' WHERE centralizing_account_name='corporeal_depreciations_inputations_expenses_living_goods'"
    # Reverse: Change item accounts#land_parcel_construction_depreciations_inputations_expenses with {:name=>"corporeal_depreciations_inputations_expenses", :fr_pcga=>"68112", :fr_pcg82=>"68112"}
    execute "UPDATE accounts SET centralizing_account_name='land_parcel_construction_depreciations_inputations_expenses' WHERE centralizing_account_name='corporeal_depreciations_inputations_expenses'"
    # Reverse: Change item accounts#animals_making_expenses_expenses with {:name=>"animals_making_expenses", :fr_pcga=>"6054"}
    execute "UPDATE accounts SET centralizing_account_name='animals_making_expenses_expenses' WHERE centralizing_account_name='animals_making_expenses'"
  end
end
