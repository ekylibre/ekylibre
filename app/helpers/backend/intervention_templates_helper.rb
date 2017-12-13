module Backend::InterventionTemplatesHelper

  def procedure_parameters(procedure)
    procedure.parameters.map do |p|
      if p.class != Procedo::Procedure::GroupParameter && !p.target?
        { name: p.human_name,
          expression: p.scope_hash,
          type: p.name,
          unities: list_of_unities(p) }
      end
    end.compact
  end

  def list_of_unities(param)
    if param.tool? || param.doer?
      { human_name: :unit.tl, name: :unit }
    else
      param.handlers.map do |handler|
        unit = handler.unit? ? handler.unit : Nomen::Unit.find(:unity)
        { human_name: "#{unit.symbol} #{handler.human_name}", name: handler.name}
      end
    end
  end
end
