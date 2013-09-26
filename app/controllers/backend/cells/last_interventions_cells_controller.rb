class Backend::Cells::LastInterventionsCellsController < Backend::CellsController

  def show
    @intervention = Intervention.last
    production = Production.find(@intervention.production_id)
    if target = @intervention.casts.where('roles ~ E?', "-target\\\\M").first
      container = Product.find(target.actor_id)
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
