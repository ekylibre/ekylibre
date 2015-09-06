class Backend::Cells::LastAnalysesCellsController < Backend::Cells::BaseController
  def show
    if @nature = Nomen::AnalysisNature[params[:nature] || 'cow_milk_analysis']
      months = params[:months].to_i
      months = 12 if months.zero?
      @product = begin
                   Product.find(params[:product_id])
                 rescue
                   nil
                 end
      @stopped_at = begin
                      params[:stopped_at].to_date
                    rescue
                      Date.today.end_of_month << 1
                    end
      @started_at = begin
                      params[:started_at].to_date
                    rescue
                      @stopped_at.beginning_of_month << (months - 1)
                    end
      @stopped_at = @started_at.end_of_month if @stopped_at < @started_at
    end
  end
end
