module Backend::InterventionTemplatesHelper

  def procedure_parameters(procedure)
    procedure.parameters.map do |p|
      if p.class != Procedo::Procedure::GroupParameter && !p.target?
        { name: p.human_name,
          expression: p.scope_hash,
          type: p.name,
          unities: list_of_unities(p),
          is_tool_or_doer: p.tool? || p.doer? }
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

  def association_activities_list
    @intervention_template.association_activities.each do |a|
      a.activity_label = a.activity.name
    end.to_json
  end

  def product_parameters_list
    @intervention_template.product_parameters.each do |i|
      i.product_name = i.product_nature&.name || i.product_nature_variant&.name
    end.to_json
  end
end
