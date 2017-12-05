class UpdateParcelItemStoringForOldReception < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute update_storing
      end

      dir.down do
        # NOOP
      end
    end
  end

  def update_storing
    <<-SQL
      -- UPDATE parcel_item_storings AS pis
      -- SET pis.product_id = parcel_items.product.id
      -- FROM parcel_items AS parcel_items
      -- WHERE pis.product_id = null
      --   AND pis.parcel_item_id = parcel_items.id
        -- AND parcel_items.type = 'ReceptionItem'
    SQL
  end
end


# need to do it on all tenant
# matters = Product.includes(:parcel_item_storings).where(type: 'Matter').where(parcel_item_storings: { product_id: nil })
# matters.each do |matter|
#   reception_items = ReceptionItem.where(product: matter, type: 'ReceptionItem')
#   reception_items.each do |r_i|
#     if r_i.storings.any?
#       r_i.storings.update_all(product_id: matter.id)
#     else
#       if r_i.reception.present?
#         ParcelItemStoring.create!( product_id: matter.id,
#                                   parcel_item_id: r_i.id,
#                                   quantity: r_i.population,
#                                   storage_id: r_i.reception.storage_id)
#       end
#     end
#     puts "------#{ r_i.id }-------"
#   end
