class Backend::WorkingSetsController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of working_sets
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => WorkingSet.all }
      format.json { render :json => WorkingSet.all }
    end
  end

  # Displays the page for one working_set
  def show
    return unless @working_set = find_and_check
    respond_to do |format|
      format.html { t3e(@working_set) }
      format.xml  { render :xml => @working_set }
      format.json { render :json => @working_set }
    end
  end

end
