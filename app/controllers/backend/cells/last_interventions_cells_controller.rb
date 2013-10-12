class Backend::Cells::LastInterventionsCellsController < Backend::CellsController

  def show
    @intervention = Intervention.last
    production = Production.find(@intervention.production_id)
    targets = @intervention.casts.of_role(:target)
    if targets.any? and target = targets.first.actor
      container = target
      # if container.is_a?(CultivableLandParcel)
      #   @container = container.class.find(container.id)
      if container.is_a?(Plant)
        @container = CultivableLandParcel.find(container.current_place_id)
      else
        @container = container
      end
    end
  end

end
