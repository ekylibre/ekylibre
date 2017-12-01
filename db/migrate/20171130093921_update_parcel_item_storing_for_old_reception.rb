class UpdateParcelItemStoringForOldReception < ActiveRecord::Migration

  class Product < ActiveRecord::Base
    self.table_name = 'products'
    has_many :localizations, foreign_key: :product_id, dependent: :destroy
    has_many :parcel_item_storings, foreign_key: :product_id
  end

  class ReceptionItem < ActiveRecord::Base
    self.table_name = 'parcel_items'
    has_many :storings, class_name: 'ParcelItemStoring', foreign_key: :parcel_item_id, dependent: :destroy
    belongs_to :product
    belongs_to :reception, foreign_key: :parcel_id
  end

  class ParcelItemStoring < ActiveRecord::Base
    self.table_name = 'parcel_item_storings'
  end

  def change
    matters = Product.includes(:parcel_item_storings).where(type: 'Matter').where(parcel_item_storings: { product_id: nil })
    matters.each do |matter|
      reception_items = ReceptionItem.where(product: matter)
      reception_items.each do |r_i|
        if r_i.storings.any?
          r_i.storings.update_all(product_id: matter.id)
        else
          if r_i.reception.present?
            ParcelItemStoring.create!( product_id: matter.id,
                                      parcel_item_id: r_i.id,
                                      quantity: r_i.population,
                                      storage_id: r_i.reception.storage_id)
          end
        end
      end
    end
  end
end
