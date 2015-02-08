class Backend::Cells::LastInterventionsCellsController < Backend::Cells::BaseController

  def show
    if @intervention = Intervention.last
      production = Production.find(@intervention.production_id)
      target = @intervention.casts.of_generic_role(:target) || @intervention.casts.of_generic_role(:input)
      if target.first
        actor = target.first.actor
        if actor
          product = Product.find(actor.id)
          # if container.is_a?(CultivableZone)
          #   @container = container.class.find(container.id)
          if product.is_a?(Plant)
            @container = CultivableZone.find(product.container)
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
