class AddMemberVariantToProductGroup < ActiveRecord::Migration[4.2]
  def change
    add_reference :products, :member_variant, index: true
  end
end
