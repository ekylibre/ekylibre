class Backend::Cells::LastInterventionsCellsController < Backend::Cells::BaseController

  def show
    scope = Intervention
    if params[:production] and production = Production.find_by(id: params[:production])
      scope = scope.where(production: production)
    end
    @intervention = scope.last
  end

end
