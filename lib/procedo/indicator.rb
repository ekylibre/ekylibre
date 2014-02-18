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
      unless value.blank?
        @value = value
        # if @indicator.datatype == :choice
        #   #   raise ArgumentError, "Unsupported type of indicator: #{indicator.inspect}. Only choices indicators are supported."
        #   # end
        #   @value = value.to_sym
        #   unless @indicator.choices.include?(@value)
        #     raise ArgumentError, "Unsupported choice #{@value.inspect} for indicator: #{indicator.inspect}. Expected choices: #{@indicator.choices.inspect}"
        #   end
        # end
      end
    end

    def inspect
      "#{self.name} (#{@task.expression} in operation #{@task.operation.name})"
    end

    def name
      "#{stakeholder.name}:#{indicator.name}"
    end

    def human_name
      :x_of_y.tl(x: @indicator.human_name, y: @stakeholder.human_name)
    end

    def value?
      @value.present?
    end

    def indicator_name
      @indicator.name
    end

    def procedure
      @task.procedure
    end

  end

end
