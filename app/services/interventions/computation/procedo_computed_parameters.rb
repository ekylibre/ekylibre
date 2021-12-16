# frozen_string_literal: true

module Interventions
  module Computation
    class ProcedoComputedParameters
      def initialize(parameters)
        @parameters = parameters
      end

      def perform
        # handle group
        if @parameters.key? 'group_parameters_attributes'
          @parameters['group_parameters_attributes'] = @parameters['group_parameters_attributes'].map do |group_parameters|
            Constants::PRODUCT_PARAMETERS.each do |collection_name|
              next if group_parameters["#{collection_name}_attributes"].blank?

              group_parameters_values = group_parameters["#{collection_name}_attributes"].select{|param| !param.key?("_destroy")}

              if group_parameters_values.blank?
                group_parameters.delete("#{collection_name}_attributes")
              else
                group_parameters_values.each do |gp_value|
                  gp_value["readings_attributes"] = gp_value["readings_attributes"].each_with_index.to_h.invert if gp_value.key?("readings_attributes")
                end
                group_parameters["#{collection_name}_attributes"] = group_parameters_values.each_with_index.to_h.invert
              end
            end

            group_parameters
          end

          group_parameters_values = @parameters['group_parameters_attributes'].select{|param| !param.key?("_destroy")}

          if group_parameters_values.blank?
            @parameters.delete('group_parameters_attributes')
          else
            @parameters['group_parameters_attributes'] = group_parameters_values.each_with_index.to_h.invert
          end

        end

        # handle root parameters
        Constants::PRODUCT_PARAMETERS.each do |collection_name|
          next if @parameters["#{collection_name}_attributes"].blank?

          parameter_values = @parameters["#{collection_name}_attributes"].select{|param| !param.key?("_destroy")}

          if parameter_values.blank?
            @parameters.delete("#{collection_name}_attributes")
          else
            parameter_values.each do |p_value|
              p_value["readings_attributes"] = p_value["readings_attributes"].each_with_index.to_h.invert if p_value.key?("readings_attributes")
            end
            @parameters["#{collection_name}_attributes"] = parameter_values.each_with_index.to_h.invert
          end
        end

        @parameters
      end
    end
  end
end
