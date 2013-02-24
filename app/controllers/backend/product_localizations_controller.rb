class Backend::ProductLocalizationsController < BackendController
  manage_restfully

  unroll_all

    list do |t|
    t.column :name, :through => :container, :url => true
    t.column :name, :through => :product, :url => true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => "RECORD.destroyable\?"
  end

  # Show a list of @product_localization
  def index
  end

  # Show one @product_localization with params_id
  def show
    return unless @product_localization = find_and_check
    session[:current_product_localization_id] = @product_localization.id
    t3e @product_localization
  end

end
