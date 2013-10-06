class Backend::CultivableLandParcelsController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
    t.column :work_number
    t.column :identification_number
    # t.column :real_quantity
    # t.column :unit
  end

  # content plant on current cultivable land parcel
  list(:contained_products, :model => :product_localizations, :conditions => {container_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :name, through: :product, url: true
    t.column :nature
    t.column :started_at
    t.column :stopped_at
  end

  # content production on current cultivable land parcel
  list(:productions, :model => :production_supports, :conditions => {storage_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :name, through: :production, url: true
    t.column :exclusive
    t.column :started_at
    t.column :stopped_at
  end

end
