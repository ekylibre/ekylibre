class Backend::ActivityWatchingsController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name,:through => :activity, :url => true
    t.column :name,:through => :product_nature, :url => true
    t.column :area_unit
    t.column :work_unit

  end

  # Displays the main page with the list of activity_watchings.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => ActivityWatching.all }
      format.json { render :json => ActivityWatching.all }
    end
  end

  # Displays the page for one activity_watching.
  def show
    return unless @activity_watching = find_and_check
    respond_to do |format|
      format.html { t3e(@activity_watching) }
      format.xml  { render :xml => @activity_watching }
      format.json { render :json => @activity_watching }
    end
  end

end
