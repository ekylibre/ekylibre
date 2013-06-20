class Backend::LegalEntitiesController < Backend::EntitiesController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
  end

  # Displays the main page with the list of legal_entities.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => LegalEntity.all }
      format.json { render :json => LegalEntity.all }
    end
  end

  # Displays the page for one legal_entity.
  def show
    return unless @legal_entity = find_and_check
    respond_to do |format|
      format.html { t3e(@legal_entity) }
      format.xml  { render :xml => @legal_entity }
      format.json { render :json => @legal_entity }
    end
  end

end
