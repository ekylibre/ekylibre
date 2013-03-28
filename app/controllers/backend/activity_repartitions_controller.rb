class Backend::ActivityRepartitionsController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :affected_on
    t.column :name, :through => :activity, :url => true
    t.column :name, :through => :product_nature, :url => true
    t.column :name, :through => :campaign, :url => true
    #t.column :id, :through => :journal_entry_item, :url => true
    t.column :state
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Displays the main page with the list of activity_repartitions.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => ActivityRepartition.all }
      format.json { render :json => ActivityRepartition.all }
    end
  end

  # Displays the page for one activity_repartition.
  def show
    return unless @activity_repartition = find_and_check
    respond_to do |format|
      format.html { t3e(@activity_repartition) }
      format.xml  { render :xml => @activity_repartition }
      format.json { render :json => @activity_repartition }
    end
  end

end
