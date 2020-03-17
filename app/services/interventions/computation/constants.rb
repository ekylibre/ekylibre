module Interventions
  module Computation
    class Constants
      PRODUCT_PARAMETERS = %i[inputs outputs doers tools targets working_periods].freeze
      PARAMETER_ACCEPTED_TYPES = { quantity_value: %i[inputs outputs], product_id: %i[targets tools doers] }.freeze
      GROUP_PARAMETER_ACCEPTED_TYPES = { quantity_value: %i[inputs], product_id: %i[targets tools doers] }.freeze
      # This list contains the readings which are allowed to be created from the API payload
      PERMITTED_READINGS = { tool: %w[hour_counter], group_parameter: { target: %w[hour_counter] } }.with_indifferent_access.freeze
    end
  end
end


