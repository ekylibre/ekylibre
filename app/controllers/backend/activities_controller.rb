class Backend::ActivitiesController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
    t.column :parent, url: true
    t.column :nature
    t.column :family
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # List of productions for one activity
  list(:productions, :conditions => {activity_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :name, url: true
    t.column :product_nature => :name, url: true
    t.column :state
    t.column :started_at
    t.column :stopped_at
    t.column :static_support
  end

end
