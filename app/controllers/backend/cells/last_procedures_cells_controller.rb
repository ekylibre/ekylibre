class Backend::Cells::LastProceduresCellsController < Backend::CellsController

  def show

    @procedure = Procedure.last
    production = Production.find(@procedure.production_id)
    target = ProcedureVariable.find_by_procedure_id_and_roles(@procedure.id,"target")
    container = Product.find(target.target_id)
    if container.is_a?(LandParcel) || container.is_a?(LandParcelGroup)
      @container = container.class.find(container.id)
    elsif container.is_a?(Plant)
      @container = LandParcelGroup.find(container.current_place_id)
    end


  end

end
