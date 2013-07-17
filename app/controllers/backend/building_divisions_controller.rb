class Backend::BuildingDivisionsController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of building_divisions.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => BuildingDivision.all }
      format.json { render :json => BuildingDivision.all }
    end
  end

  # Displays the page for one building_division.
  def show
    return unless @building_division = find_and_check
    respond_to do |format|
      format.html { t3e(@building_division) }
      format.xml  { render :xml => @building_division }
      format.json { render :json => @building_division }
    end
  end

end
