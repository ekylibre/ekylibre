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
    respond_to do |format|
      format.html { t3e(@cultivable_land_parcel) }
      format.xml  { render :xml => @cultivable_land_parcel }
      format.json { render :json => @cultivable_land_parcel }
    end
  end

end