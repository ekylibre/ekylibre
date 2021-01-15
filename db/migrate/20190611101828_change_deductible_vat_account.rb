# Migration generated with nomenclature migration #20190611101014
class ChangeDeductibleVatAccount < ActiveRecord::Migration[4.2]
  def up
    execute "UPDATE accounts SET centralizing_account_name='deductible_products_and_services_vat' WHERE centralizing_account_name='deductible_vat'"
    execute "UPDATE accounts SET centralizing_account_name='deductible_vat' WHERE centralizing_account_name='enterprise_deductible_vat'"
    execute "UPDATE accounts SET usages='deductible_products_and_services_vat' WHERE usages='deductible_vat'"
    execute "UPDATE accounts SET usages='deductible_vat' WHERE usages='enterprise_deductible_vat'"
  end

  def down
    execute "UPDATE accounts SET centralizing_account_name='enterprise_deductible_vat' WHERE centralizing_account_name='deductible_vat'"
    execute "UPDATE accounts SET centralizing_account_name='deductible_vat' WHERE centralizing_account_name='deductible_products_and_services_vat'"
    execute "UPDATE accounts SET usages='enterprise_deductible_vat' WHERE usages='deductible_vat'"
    execute "UPDATE accounts SET usages='deductible_vat' WHERE usages='deductible_products_and_services_vat'"
  end
end
