module Procedo

  class Indicator
    
    attr_reader :task, :stakeholder, :indicator, :value

    def initialize(task, stakeholder, indicator, value = nil)
      @task = task
      unless @stakeholder = @task.procedure.variables[stakeholder]
        raise ArgumentError, "Unknown stakeholder: #{stakeholder.inspect}"
      end
      unless @indicator = Nomen::Indicators[indicator]
        raise ArgumentError, "Unknown indicator: #{indicator.inspect}"
      end
      unless value.nil?
        unless @indicator.datatype == :choice
          raise ArgumentError, "Unsupported type of indicator: #{indicator.inspect}. Only choices indicators are supported."
        end
        @value = value.to_sym
        unless @indicator.choices.include?(@value)
          raise ArgumentError, "Unsupported choice #{@value.inspect} for indicator: #{indicator.inspect}. Expected choices: #{@indicator.choices.inspect}"
        end
      end
    end

    def human_name
      :x_of_y.tl(x: @indicator.human_name, y: @stakeholder.human_name)
    end

  end

end
