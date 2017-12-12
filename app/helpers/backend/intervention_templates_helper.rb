module Backend::InterventionTemplatesHelper

  def procedure_parameters(procedure)
    procedure.parameters.map do |p|
      { name: p.human_name,
        expression: p.scope_hash,
        type: p.name,
        unities: list_of_unities(p) } unless p.target?
    end.compact
  end

  def list_of_unities(param)
    if param.tool? || param.doer?
      [:unit]
    else
      param.handlers.map do |handler|
        unit = handler.unit? ? handler.unit : Nomen::Unit.find(:unity)
        { human_name: "#{unit.symbol} #{handler.human_name}", name: handler.name}
      end
    end
  end
end
