module Backend
  class ServicesController < Backend::BaseController

    def self.services_conditions
      code = search_conditions(product_nature_variants: %i[name number]) + " ||= []\n"
      code << "c[0] << \" AND product_nature_variants.variety = 'service'\"\n"
      code << "c\n"
      code.c
    end

    list(model: :product_nature_variants, conditions: services_conditions) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :number
      t.column :nature, url: true
      t.column :category, url: true
      t.column :quantity_purchased
      t.column :quantity_received
      t.column :current_stock
      t.column :unit_name
      t.column :active
    end

    def index; end
  end
end
