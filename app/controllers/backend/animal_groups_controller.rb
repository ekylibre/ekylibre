class Backend::AnimalGroupsController < BackendController
  manage_restfully

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll

  list do |t|
    t.column :name, url: true
    t.column :description
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Liste des animaux d'un groupe d'animaux considéré
  list(:animals, :model => :product_memberships, :conditions => [" group_id = ? ",'params[:id]'.c], :order => "started_at ASC") do |t|
    t.column :name, through: :member, url: true
    t.column :started_at
    t.column :stopped_at
  end

  # Liste des lieux du groupe d'animaux considéré
  list(:places, :model => :product_localizations, :conditions => [" product_id = ? ",'params[:id]'.c], :order => "started_at DESC") do |t|
    t.column :name, through: :container, url: true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

end
