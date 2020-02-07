module Interventions
  module Computation
    class ExtractReadings
      def initialize(attributes)
        @attributes = attributes
      end

      def perform
        readings = {}
        Constants::PERMITTED_READINGS.keys.each do |reading_param|
          if reading_param == "group_parameter" && @attributes.include?("group_parameters_attributes")
            Constants::PERMITTED_READINGS[:group_parameter].keys.each do |group_reading_param|
              param_key = "#{group_reading_param.pluralize}_attributes"
              @attributes["group_parameters_attributes"].each_with_index do |gp_attrs, index|
                next if gp_attrs[param_key].blank?
                next if gp_attrs[param_key].none? {|attrs| attrs.key?(:readings_attributes)}
                readings["group_parameter"] ||= {}
                readings["group_parameter"][index] = {}
                readings["group_parameter"][index]["#{group_reading_param}"] = @attributes["group_parameters_attributes"][index][param_key].flat_map {|attrs| attrs.delete(:readings_attributes) }.first
              end
            end
          else
            param_key = "#{reading_param.pluralize}_attributes"
            next if @attributes[param_key].blank?
            next if @attributes[param_key].none? {|attrs| attrs.key?(:readings_attributes)}
            readings["#{reading_param}"] = @attributes[param_key].flat_map {|attrs| attrs.delete(:readings_attributes) }.each_with_index.to_h.invert.compact
          end
        end
        # IE : readings = {"tool"=>{0=>{"indicator_name"=>"hour_counter", "measure_value_value"=>"8", "measure_value_unit"=>"hour"}, 2=>{"indicator_name"=>"hour_counter", "measure_value_value"=>"5", "measure_value_unit"=>"hour"}}}
        readings
      end
    end
  end
end
