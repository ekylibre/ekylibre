class Backend::ProductNatureVariantsController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
    t.column :name, :through => :nature, url: true
    t.column :unit_name
    t.column :frozen_indicators
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  list(:prices, :model => :catalog_prices, :conditions => {variant_id: ['params[:id]']}, :order => "started_at DESC") do |t|
    t.column :pretax_amount, url: true
    t.column :started_at
    t.column :stopped_at
    t.column :name, :through => :supplier, url: true
    t.column :name, :through => :catalog, url: true
  end

  list(:products, :model => :products, :conditions => {variant_id: ['params[:id]']}, :order => "born_at DESC") do |t|
    t.column :name, url: true
    t.column :identification_number
    t.column :born_at
    t.column :net_weight
    t.column :net_volume
    t.column :population
  end

end
