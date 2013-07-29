class Backend::ServicesController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of services.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => Service.all }
      format.json { render :json => Service.all }
    end
  end

  # Displays the page for one service.
  def show
    return unless @service = find_and_check
    respond_to do |format|
      format.html { t3e(@service) }
      format.xml  { render :xml => @service }
      format.json { render :json => @service }
    end
  end

end
