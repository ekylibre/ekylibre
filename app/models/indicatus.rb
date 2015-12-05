class Indicatus
  def initialize(variable_indicator, operation)
    @varicator = variable_indicator
    @operation = operation
    @intervention = @operation.intervention
  end

  def value?
    @varicator.value?
  end

  def indicator
    @varicator.indicator
  end

  def name
    @varicator.indicator_name
  end

  def reading
    Reading.new(@varicator.indicator_name, computed_value)
  end

  def actor
    if cast = @intervention.casts.find_by(reference_name: @varicator.stakeholder.name)
      return cast.actor
    else
      return nil
    end
  end

  def computed_value(_options = {})
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
          if source_actor.indicators_list.include?(:shape)
            if actor.indicators_list.include?(:net_surface_area)
              if source_cast.shape
                whole = Charta.new_geometry(source_cast.shape).area
              elsif whole = source_actor.shape_area(at: @operation.started_at)
              #
              else
                fail StandardError, "Cannot compute superficial count if with a source product without shape reading (#{source_cast.shape.inspect})"
              end
              return 0 if whole.zero?
              individual = actor.net_surface_area(@operation.stopped_at, gathering: false, default: false)
              if individual.nil?
                fail StandardError, 'Cannot compute superficial count with a product with null net_surface_area indicator. Maybe indicator is variable and not already read.'
              end
              return (whole.to_f(:square_meter) / individual.to_f(:square_meter))
            else
              fail StandardError, 'Cannot compute superficial count with a product without net_surface_area indicator'
            end
          else
            fail StandardError, "Cannot compute superficial count with a source product without shape indicator #{source_actor.nature.inspect}"
          end
        else # if computation == :same_as
          if source_actor.indicators.include?(@varicator.indicator)
            return source_actor.get!(@varicator.indicator, @operation.started_at)
          else
            fail StandardError, "Cannot get #{@varicator.indicator_name} from a source product without this indicator #{source_actor.nature.inspect}."
          end
        end
      else
        # Direct value
        return expr
      end
    else
      fail NotImplementedError
    end
  end
end
