class Indicatus

  def initialize(variable_indicator, operation)
    @varicator = variable_indicator
    @operation = operation
    @intervention = @operation.intervention
  end

  def value?
    @varicator.value?
  end

  def datum
    IndicatorDatum.new(@varicator.indicator_name, computed_value)
  end

  def actor
    if cast = @intervention.casts.find_by(reference_name: @varicator.stakeholder.name)
      return cast.actor
    else
      return nil
    end
  end

  protected

  def computed_value(options = {})
    if @varicator.value?
      expr = @varicator.value.strip
      # Computed value
      if expr =~ /\A(\w+)?[[:space:]]*\:[[:space:]]*\w+\z/
        computation, var = expr.split(/[[:space:]]*\:[[:space:]]*/)[0..1]
        computation = (computation.blank? ? :same_as : computation.underscore.to_sym)
        source_var = @varicator.procedure.variables[var]
        source_cast = @intervention.casts.find_by(reference_name: source_var.name.to_s)
        source_actor = source_cast.actor
        cast  = @intervention.casts.find_by(reference_name: @varicator.stakeholder.name)
        actor = cast.actor
        if computation == :superficial_count
          if source_actor.indicators_list.include?(:shape) and actor.indicators_list.include?(:net_surface_area)
            whole      = source_actor.net_surface_area(@operation.started_at).to_d(:square_meter) rescue 0
            individual = actor.net_surface_area(@operation.started_at, gathering: false).to_d(:square_meter)
            return (whole / individual)
          else
            # raise StandardError, "Cannot compute superficial count if no shape and net_surface_area given."
            Rails.logger.warn "Cannot compute superficial count if no shape and net_surface_area given."
          end
        else # if computation == :same_as
          if source_actor.whole_indicators_list.include?(@varicator.indicator_name.to_sym) and cast.reference.new?
            return actor.get(@varicator.indicator, cast)
          elsif datum = cast.actor.indicator_datum(@varicator.indicator, at: @operation.started_at)
            return datum.value
          else
            return nil
          end
        end
      else
        # Direct value
        return expr
      end
    else
      raise NotImplementedError
    end
  end

end
