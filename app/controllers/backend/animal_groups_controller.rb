class Backend::AnimalGroupsController < BackendController
  manage_restfully

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :description
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Liste des animaux d'un groupe d'animaux considéré
  list(:animals, :model => :product_memberships, :conditions => [" group_id = ? ",['session[:current_animal_group_id]']], :order => "started_at ASC") do |t|
    t.column :name, :through => :member, :url => true
    t.column :started_at
    t.column :stopped_at
  end

  # Liste des lieux du groupe d'animaux considéré
  list(:place, :model => :product_localizations, :conditions => [" product_id = ? ",['session[:current_animal_group_id]']], :order => "started_at DESC") do |t|
    t.column :name, :through => :container, :url => true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

  # Displays the main page with the list of animal_groups.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => AnimalGroup.all }
      format.json { render :json => AnimalGroup.all }
    end
  end

  # Displays the page for one animal_group.
  def show
    return unless @animal_group = find_and_check
    session[:current_animal_group_id] = @animal_group.id
    respond_to do |format|
      format.html { t3e(@animal_group) }
      format.xml  { render :xml => @animal_group }
      format.json { render :json => @animal_group }
    end
  end

end
