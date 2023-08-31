class AddSaleContractNatures < ActiveRecord::Migration[4.2]
  def change
    create_table :sale_contract_natures do |t|
      t.string :name, null: false
      t.string :template_name
      t.text :comment
      t.stamps
    end

    add_reference :sale_contracts, :nature, index: true
  end
end
