class Backend::IncidentsController < BackendController

  manage_restfully
  manage_restfully_picture

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll

  list do |t|
    t.column :name, url: true
    t.column :nature
    t.column :observed_at
    # t.column :name, through: :target, url: true
    t.column :gravity
    t.column :priority
    t.column :state
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end


  list(:interventions, :conditions => {incident_id: 'params[:id]'.c}, :order => "created_at DESC") do |t|
    t.column :nomen, url: true
    t.column :created_at
    t.column :natures
    t.column :state
  end

end
