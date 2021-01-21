class AddClientReferenceFieldToSales < ActiveRecord::Migration[4.2]
  def change
    add_column :sales, :client_reference, :string
  end
end
