class Backend::OperationNaturesController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of operation_natures
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => OperationNature.all }
      format.json { render :json => OperationNature.all }
    end
  end

  # Displays the page for one operation_nature
  def show
    return unless @operation_nature = find_and_check
    respond_to do |format|
      format.html { t3e(@operation_nature) }
      format.xml  { render :xml => @operation_nature }
      format.json { render :json => @operation_nature }
    end
  end

end
