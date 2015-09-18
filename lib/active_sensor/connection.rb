module ActiveSensor
  class Connection
    attr_accessor :equipment, :controller, :parameters

    def initialize(equipment, parameters = {})
      @equipment = equipment
      if equipment.controller
        @controller = equipment.controller.new
        @parameters = {}.with_indifferent_access
        equipment.parameters.each do |name, parameter|
          @parameters[name] = parameter.normalize!(parameters[name.to_s])
        end
      end
    end

    def retrieve(options = {})
      unless controller
        return { status: :error, message: "No controller given for #{equipment.unique_name}" }
      end
      begin
        report = @controller.retrieve(parameters, options)
      rescue StandardError => e
        report = { status: :controller_error, message: e.message }
      end
      report
    end
  end
end
