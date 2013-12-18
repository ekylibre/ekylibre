class Indicatus

  def initialize(variable_indicator, operation)
    @varicator = variable_indicator
    @operation = operation
    @intervention = @operation.intervention
  end

  def value?
    @value.present?
  end

  def datum
    IndicatorDatum.new(@varicator.indicator_name, computed_value)
  end

  def actor
    @intervention.casts.find_by(reference_name: @varicator.stakeholder.name)
  end

  protected

  def computed_value(options = {})
    if @varicator.value?
      expr = @varicator.value.strip
      # Computed value
      if expr =~ /\A(\w+)?[[:space:]]*\:[[:space:]]*\w+\z/
        computation, var = expr.split(/[[:space:]]*\:[[:space:]]*/)[0..1]
        computation = (computation.blank? ? :same_as : computation.underscore.to_sym)
        var = @varicator.procedure.variables[var]
        if computation == :superficial_count

          return IndicatorDatum.new(:population, 0.0)
        else # if computation == :same_as
          cast = @intervention.casts.find_by(reference_name: var.name.to_s)
          pid = cast.actor.indicator_datum(@varicator.indicator, at: @operation.started_at)
          return pid.indicator_datum
        end
      else
        # Direct value
        return IndicatorDatum.new(@varicator.indicator_name, expr)
      end
    else
      raise NotImplementedError
    end
  end

end
