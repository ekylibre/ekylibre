class Backend::Cells::LastInterventionsCellsController < Backend::CellsController

  def show
    if @intervention = Intervention.last
      production = Production.find(@intervention.production_id)
      target = @intervention.casts.of_role(:target) || @intervention.casts.of_role(:input)
      if target.first
        actor = target.first.actor
        if actor
          product = Product.find(actor.id)
          # if container.is_a?(CultivableLandParcel)
          #   @container = container.class.find(container.id)
          if product.is_a?(Plant)
            @container = CultivableLandParcel.find(product.container)
          elsif product.is_a?(Animal)
            @container = BuildingDivision.find(product.container)
          else
            @container = product
          end
        end
      end
    end
  end

end
