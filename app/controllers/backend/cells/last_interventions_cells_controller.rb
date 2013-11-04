class Backend::Cells::LastInterventionsCellsController < Backend::CellsController

  def show
    if @intervention = Intervention.last
      production = Production.find(@intervention.production_id)
      target = @intervention.casts.of_role(:target) || @intervention.casts.of_role(:input)
      if target.first
        actor = target.first.actor
        if actor
          container = Product.find(actor.id)
          # if container.is_a?(CultivableLandParcel)
          #   @container = container.class.find(container.id)
          if container.is_a?(Plant)
            @container = CultivableLandParcel.find(container.current_place_id)
          elsif container.is_a?(Animal)
            @container = BuildingDivision.find(container.current_place_id)
          else
            @container = container
          end
        end
      end
    end
  end

end
