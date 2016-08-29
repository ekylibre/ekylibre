class AddMemberVariantToProductGroup < ActiveRecord::Migration
  def change
    add_column :products, :member_variant_id, :integer
    add_index :products, :member_variant_id
  end
end
