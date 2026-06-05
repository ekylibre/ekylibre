class AddCertiphytoToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :certiphyto_number, :string
    add_column :products, :certiphyto_kind, :string
    add_column :products, :certiphyto_expires_on, :date
    add_index :products, :certiphyto_expires_on
  end
end
