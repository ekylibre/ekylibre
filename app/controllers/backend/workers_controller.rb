class Backend::WorkersController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of workers.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => Worker.all }
      format.json { render :json => Worker.all }
    end
  end

  # Displays the page for one worker.
  def show
    return unless @worker = find_and_check
    respond_to do |format|
      format.html { t3e(@worker) }
      format.xml  { render :xml => @worker }
      format.json { render :json => @worker }
    end
  end

end
