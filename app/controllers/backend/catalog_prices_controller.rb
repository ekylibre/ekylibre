class Backend::CatalogPricesController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, through: :variant, url: true
    t.column :amount
    t.column :started_at
    t.column :stopped_at
    t.column :name, through: :reference_tax, url: true
    t.column :all_taxes_included
    t.column :name, through: :catalog, url: true
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

end
