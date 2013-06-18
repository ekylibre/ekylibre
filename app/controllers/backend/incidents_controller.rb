class Backend::IncidentsController < BackendController

  manage_restfully

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :nature
    #t.column :name, :through => :target, :url => true
    t.column :gravity
    t.column :priority
    t.column :state
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Displays the main page with the list of incidents.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => Incident.all }
      format.json { render :json => Incident.all }
    end
  end

  # Displays the page for one incident.
  def show
    return unless @incident = find_and_check
    t3e @incident
    session[:current_incident_id] = @incident.id
    respond_with(@incident, :include => [:procedures, :target])
  end

end
