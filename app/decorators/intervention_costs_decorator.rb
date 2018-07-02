class InterventionCostsDecorator < Draper::Decorator
  delegate_all

  def to_h
    {
      total: total_cost,
      inputs: inputs_cost,
      doers: doers_cost,
      tools: tools_cost,
      receptions: receptions_cost
    }
  end

  def to_human_h
    {
      total: human_total_cost,
      inputs: human_inputs_cost,
      doers: human_doers_cost,
      tools: human_tools_cost,
      receptions: human_receptions_cost
    }
  end

  def human_total_cost
    human_cost(total_cost)
  end

  def human_inputs_cost
    human_cost(object.inputs_cost)
  end

  def human_doers_cost
    human_cost(object.doers_cost)
  end

  def human_tools_cost
    human_cost(object.tools_cost)
  end

  def human_receptions_cost
    human_cost(object.receptions_cost)
  end

  private

  def human_cost(cost)
    cost
      .to_f
      .round(2)
  end

  def total_cost
    object.inputs_cost +
      object.doers_cost +
      object.tools_cost +
      object.receptions_cost
  end
end
