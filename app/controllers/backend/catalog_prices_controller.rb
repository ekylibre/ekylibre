class Backend::CatalogPricesController < BackendController
  manage_restfully

  unroll

#  all_taxes_included :boolean          not null
#  amount             :decimal(19, 4)   not null
#  catalog_id         :integer
#  created_at         :datetime         not null
#  creator_id         :integer
#  currency           :string(3)        not null
#  id                 :integer          not null, primary key
#  indicator          :string(120)      not null
#  lock_version       :integer          default(0), not null
#  reference_tax_id   :integer          not null
#  started_at         :datetime
#  stopped_at         :datetime
#  supplier_id        :integer          not null
#  thread             :string(20)
#  updated_at         :datetime         not null
#  updater_id         :integer
#  variant_id         :integer          not null

  list do |t|
    t.column :name, through: :variant, url: true
    t.column :amount
    t.column :started_at
    t.column :stopped_at
    t.column :name, through: :reference_tax, url: true
    t.column :all_taxes_included
    t.column :name, through: :supplier, url: true
    t.column :name, through: :catalog, url: true
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

end
