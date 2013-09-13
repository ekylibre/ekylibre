class Backend::CatalogPricesController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, through: :variant, url: true
    t.column :pretax_amount
    t.column :started_at
    t.column :stopped_at
    t.column :name, through: :supplier, url: true
    t.column :name, through: :catalog, url: true
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

end
