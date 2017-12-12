module Backend::InterventionTemplatesHelper

  def procedure_parameters(procedure)
    procedure.parameters.map do |p|
      { name: p.human_name, expression: p.scope_hash, type: p.name } unless p.target?
    end.compact
  end
end
