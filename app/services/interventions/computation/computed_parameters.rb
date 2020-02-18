module Interventions
  module Computation
    class ComputedParameters
      def initialize(parameters)
        @parameters = parameters
      end

      def perform
        # handle group
        if @parameters.key? 'group_parameters_attributes'
          @parameters['group_parameters_attributes'] = @parameters['group_parameters_attributes'].map do |group_parameters|

            Constants::PRODUCT_PARAMETERS.each do |collection_name|
              next if group_parameters["#{collection_name}_attributes"].blank?

              group_parameters["#{collection_name}_attributes"] = group_parameters["#{collection_name}_attributes"].each_with_index.to_h.invert
            end

            group_parameters
          end
          @parameters['group_parameters_attributes'] = @parameters['group_parameters_attributes'].each_with_index.to_h.invert
        end

        # handle root parameters
        Constants::PRODUCT_PARAMETERS.each do |collection_name|
          next if @parameters["#{collection_name}_attributes"].blank?

          @parameters["#{collection_name}_attributes"] = @parameters["#{collection_name}_attributes"].each_with_index.to_h.invert
        end

        @parameters
      end
    end
  end
end

