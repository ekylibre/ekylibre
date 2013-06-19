class Backend::ProceduresController < BackendController
  manage_restfully

  unroll_all

  list :conditions => {:parent_id => nil} do |t|
    t.column :nomen, :url => true
    t.column :name, :through => :activity, :url => true
    t.column :name, :through => :campaign, :url => true
    t.column :name, :through => :incident, :url => true
    t.column :state
    t.column :variables_names
    t.action :run
    t.action :destroy, :if => :destroyable?
  end

  # Displays the main page with the list of procedures
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => Procedure.all }
      format.json { render :json => Procedure.all }
    end
  end

  # Displays the page for one procedure
  def show
    return unless @procedure = find_and_check
    respond_to do |format|
      format.html { t3e(@procedure) }
      format.xml  { render :xml => @procedure }
      format.json { render :json => @procedure }
    end
  end

end
