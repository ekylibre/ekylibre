class Backend::CultivableLandParcelsController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
    t.column :work_number
    t.column :identification_number
    #t.column :real_quantity
    #t.column :unit
  end

  # content plant on current cultivable land parcel
  list(:content_products, :model => :product_localizations, :conditions => ["container_id = ? ",'params[:id]'.c], :order => "started_at DESC") do |t|
    t.column :name, through: :product, url: true
    t.column :nature
    t.column :started_at
    t.column :stopped_at
  end

  # content production on current cultivable land parcel
  list(:productions, :model => :production_supports, :conditions => ["storage_id = ? ",'params[:id]'.c], :order => "started_at DESC") do |t|
    t.column :name, through: :production, url: true
    t.column :exclusive
    t.column :started_at
    t.column :stopped_at
  end

  list(:intervention_casts, :conditions => {actor_id: 'params[:id]'.c}) do |t|
    t.column :name, through: :intervention, url: true
    t.column :roles
    t.column :variable
    t.column :started_at, through: :intervention
    t.column :stopped_at, through: :intervention
  end

  # INDEX


  # SHOW


end