class Backend::ProceduresController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
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
