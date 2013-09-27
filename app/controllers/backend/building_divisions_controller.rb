class Backend::BuildingDivisionsController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
    t.column :identification_number
    t.column :work_number
    t.column :description
    t.action :edit
    t.action :destroy
  end

  # Liste des produits présent dans cette localisation
  list(:content_product, :model => :product_localizations, :conditions => ["container_id = ? ",['session[:current_building_division_id]']], :order => "started_at DESC") do |t|
    t.column :name, through: :product, url: true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

  # Displays the main page with the list of building_divisions.
  def index
    session[:viewed_on] = params[:viewed_on] = params[:viewed_on].to_date rescue Date.today
    respond_to do |format|
      format.html
      format.xml  { render :xml => BuildingDivision.all }
      format.json { render :json => BuildingDivision.all }
    end
  end

  # Displays the page for one building_division.
  def show
    return unless @building_division = find_and_check(:building_divisions)
    session[:current_building_division_id] = @building_division.id
    t3e @building_division.attributes
    respond_to do |format|
      format.html { t3e(@building_division) }
      format.xml  { render :xml => @building_division }
      format.json { render :json => @building_division }
    end
  end

end
