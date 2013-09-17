class Backend::ProductionSupportsController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of production_supports.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => ProductionSupport.all }
      format.json { render :json => ProductionSupport.all }
    end
  end

  # Displays the page for one production_support.
  def show
    return unless @production_support = find_and_check
    respond_to do |format|
      format.html { t3e(@production_support) }
      format.xml  { render :xml => @production_support }
      format.json { render :json => @production_support }
    end
  end

end
