class Backend::LandParcelGroupsController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, :url => true
    t.column :work_number
    t.column :identification_number
    #t.column :real_quantity
    #t.column :unit
  end

  # Displays the main page with the list of land_parcel_groups.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => LandParcelGroup.all }
      format.json { render :json => LandParcelGroup.all }
    end
  end

  # Displays the page for one land_parcel_group.
  def show
    return unless @land_parcel_group = find_and_check
    respond_to do |format|
      format.html { t3e(@land_parcel_group) }
      format.xml  { render :xml => @land_parcel_group }
      format.json { render :json => @land_parcel_group }
    end
  end

end
