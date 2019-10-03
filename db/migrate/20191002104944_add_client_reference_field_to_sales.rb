class AddClientReferenceFieldToSales < ActiveRecord::Migration
  def change
    add_column :sales, :client_reference, :string
  end
end
