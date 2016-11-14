class AddMemberVariantToProductGroup < ActiveRecord::Migration
  def change
    add_reference :products, :member_variant, index: true
  end
end
