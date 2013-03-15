class Backend::ProcedureNaturesController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of procedure_natures
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => ProcedureNature.all }
      format.json { render :json => ProcedureNature.all }
    end
  end

  # Displays the page for one procedure_nature
  def show
    return unless @procedure_nature = find_and_check
    respond_to do |format|
      format.html { t3e(@procedure_nature) }
      format.xml  { render :xml => @procedure_nature }
      format.json { render :json => @procedure_nature }
    end
  end

end
