class Backend::Cells::LastMilkResultCellsController < Backend::CellsController

  list(model: :product_indicator_data, joins: {product: :nature}, conditions: {indicator_name: 'milk'}, order: {measured_at: :desc, id: :desc}, per_page: 10) do |t|
    t.column :indicator_name #, :url => true
    t.column :name, through: :product, url: {controller: "'/backend/products'"}
    t.column :value
    t.column :measured_at
  end

  def show
    camp = Campaign.find(params[:campaign_id]) rescue nil
    @campaign =  camp || Campaign.currents.reorder('harvest_year DESC').first
  end

end
