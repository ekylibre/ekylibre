module Interventions
  module Computation
    class AddCustomReadings
      def initialize(engine_intervention, readings)
        @engine_intervention = engine_intervention
        @readings = readings
      end

      def perform
        Constants::PERMITTED_READINGS.each do |reading_param, reading_names|
          engine_parameters = @engine_intervention.parameters_of_type(reading_param)
          next if engine_parameters.empty?
          next if @readings[reading_param].nil?
          if reading_param == "group_parameter"
            reading_index = 0
            engine_parameters.each_with_index do |gp_engine_param, gp_index|
              if gp_reading = @readings[reading_param][gp_index]
                # gp_reading = {"target"=>{"indicator_name"=>"hour_counter", "measure_value_value"=>"23", "measure_value_unit"=>"hour"}}
                # reading_names = {"target"=>["hour_counter"]}
                gp_reading.each do |gp_reading_key, gp_reading_attrs|
                  # gp_reading_key = "target"
                  # gp_reading_attrs = {"indicator_name"=>"hour_counter", "measure_value_value"=>"23", "measure_value_unit"=>"hour"}
                  next if reading_names.keys.exclude?(gp_reading_key)
                  engine_param = gp_engine_param.parameters_of_type(gp_reading_key.to_sym).first
                  indicator_name = gp_reading_attrs["indicator_name"]
                  engine_param.reference.add_reading(indicator_name) if engine_param.reference.readings.map(&:name).exclude?(indicator_name.to_sym)
                  engine_param.add_reading(reading_index, gp_reading_attrs)
                  reading_index += 1
                end
              end
            end
          else
            reading_index = 0
            engine_parameters.each_with_index do |engine_param, index|
              if engine_reading = @readings[reading_param][index]
                indicator_name = engine_reading["indicator_name"]
                next if reading_names.exclude?(indicator_name)
                # Procedo hack :  Reading need to be added to the reference of the parameter then to the parameter itself in order to be recorded
                engine_param.reference.add_reading(indicator_name) if engine_param.reference.readings.map(&:name).exclude?(indicator_name.to_sym)
                engine_param.add_reading(reading_index, engine_reading)
                reading_index += 1
              end
            end
          end
        end
      end
    end
  end
end

