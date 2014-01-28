class Backend::Cells::GuideEvolutionCellsController < Backend::CellsController

  def show
    @show_title = true
    if params[:id]
      @show_title = false
      return unless @guide = Guide.find_by(id: params[:id])
    elsif analysis = GuideAnalysis.latests.order(created_at: :desc).first
      @guide = analysis.guide
    end
  end

end
