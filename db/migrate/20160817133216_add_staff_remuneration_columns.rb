class AddStaffRemunerationColumns < ActiveRecord::Migration
  def change
    add_column :purchase_natures, :nature, :string
    reversible do |dir|
      dir.up do
        execute "UPDATE purchase_natures SET nature = 'purchase'"
      end
    end
    change_column_null :purchase_natures, :nature, false

    add_column :entities, :employee, :boolean, null: false, default: false
    add_reference :entities, :employee_account, index: true
  end
end
