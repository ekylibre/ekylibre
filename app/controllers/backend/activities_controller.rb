class Backend::ActivitiesController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :parent, :url => true
    t.column :nature
    t.column :family
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # List of productions for one activity
  list(:production, :model => :productions, :conditions => [" activity_id = ? ",['session[:current_activity_id]']], :order => "started_at DESC") do |t|
    t.column :name, :through => :product_nature, :url => true
    t.column :name, :through => :campaign, :url => true
    t.column :state
    t.column :started_at
    t.column :stopped_at
    t.column :static_support
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
    session[:current_activity_id] = @activity.id
    respond_to do |format|
      format.html { t3e(@activity) }
      format.xml  { render :xml => @activity }
      format.json { render :json => @activity }
    end
  end

end
