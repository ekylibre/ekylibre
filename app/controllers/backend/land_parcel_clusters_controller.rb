class Backend::LandParcelClustersController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :work_number
    t.column :identification_number
    #t.column :real_quantity
    #t.column :unit

  end

  # Displays the main page with the list of land_parcel_clusters.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => LandParcelCluster.all }
      format.json { render :json => LandParcelCluster.all }
    end
  end

  # Displays the page for one land_parcel_cluster.
  def show
    return unless @land_parcel_cluster = find_and_check
    respond_to do |format|
      format.html { t3e(@land_parcel_cluster) }
      format.xml  { render :xml => @land_parcel_cluster }
      format.json { render :json => @land_parcel_cluster }
    end
  end

end
