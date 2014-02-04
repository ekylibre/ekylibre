class Backend::Cells::LastMilkResultCellsController < Backend::CellsController

  list(model: :product_indicator_data, joins: {product: :nature}, conditions: {indicator_name: 'milk'}, order: {measured_at: :desc, id: :desc}, per_page: 10) do |t|
    t.column :indicator_name #, :url => true
    t.column :name, through: :product, url: {controller: "'/backend/products'"}
    t.column :value
    t.column :measured_at
  end

  def show
    # camp = Campaign.find(params[:campaign_id]) rescue nil
    # @campaign =  camp || Campaign.currents.reorder('harvest_year DESC').first
    months = params[:months].to_i
    months = 12 if months.zero?
    @stopped_at = params[:stopped_at].to_date rescue Date.today.end_of_month << 1
    @started_at = params[:started_at].to_date rescue @stopped_at.beginning_of_month << (months - 1)
    @stopped_at = @started_at.end_of_month if @stopped_at < @started_at
  end

end
