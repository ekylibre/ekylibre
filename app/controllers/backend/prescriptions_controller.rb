class Backend::PrescriptionsController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :reference_number, :url => true
    t.column :delivered_on
    t.column :name, :through =>:prescriptor, :url => true
    t.column :name, :through =>:document, :url => true
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Displays the main page with the list of prescriptions.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => Prescription.all }
      format.json { render :json => Prescription.all }
    end
  end

  # Displays the page for one prescription.
  def show
    return unless @prescription = find_and_check
    respond_to do |format|
      format.html { t3e(@prescription) }
      format.xml  { render :xml => @prescription }
      format.json { render :json => @prescription }
    end
  end

end
