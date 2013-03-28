class Backend::ActivitiesController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :parent, :url => true
    t.column :nature
    t.column :family
    t.column :area_unit
    t.column :work_unit
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Displays the main page with the list of activities.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => Activity.all }
      format.json { render :json => Activity.all }
    end
  end

  # Displays the page for one activity.
  def show
    return unless @activity = find_and_check
    respond_to do |format|
      format.html { t3e(@activity) }
      format.xml  { render :xml => @activity }
      format.json { render :json => @activity }
    end
  end

end
