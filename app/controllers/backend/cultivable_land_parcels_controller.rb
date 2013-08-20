class Backend::CultivableLandParcelsController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :work_number
    t.column :identification_number
    #t.column :real_quantity
    #t.column :unit
  end

  # content plant on current cultivable land parcel
  list(:content_products, :model => :product_localizations, :conditions => ["container_id = ? ",['session[:current_cultivable_land_parcel_id]']], :order => "started_at DESC") do |t|
    t.column :name, :through => :product, :url => true
    t.column :nature
    t.column :started_at
    t.column :stopped_at
  end

  # content production on current cultivable land parcel
  list(:productions, :model => :production_supports, :conditions => ["storage_id = ? ",['session[:current_cultivable_land_parcel_id]']], :order => "started_at DESC") do |t|
    t.column :name, :through => :production, :url => true
    t.column :exclusive
    t.column :started_at
    t.column :stopped_at
  end


  # Displays the main page with the list of cultivable_land_parcels.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => CultivableLandParcel.all }
      format.json { render :json => CultivableLandParcel.all }
    end
  end

  # Displays the page for one cultivable_land_parcel.
  def show
    return unless @cultivable_land_parcel = find_and_check
    session[:current_cultivable_land_parcel_id] = @cultivable_land_parcel.id
    t3e @cultivable_land_parcel
    respond_to do |format|
      format.html { t3e(@cultivable_land_parcel) }
      format.xml  { render :xml => @cultivable_land_parcel }
      format.json { render :json => @cultivable_land_parcel }
    end
  end

end