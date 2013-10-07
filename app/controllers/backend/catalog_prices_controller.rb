class Backend::CatalogPricesController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :variant => :name, url: true
    t.column :amount
    t.column :started_at
    t.column :stopped_at
    t.column :reference_tax => :name, url: true
    t.column :all_taxes_included
    t.column :catalog => :name, url: true
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

end
