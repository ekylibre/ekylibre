# frozen_string_literal: true

module Interventions
  module Computation
    class AddNecessaryAttributes
      def initialize(parameters)
        @parameters = parameters
      end

      def perform
        add_working_zone_attribute_to_group_parameters(@parameters.fetch(:group_parameters_attributes, []))

        add_working_zone_attribute_to_parameters(@parameters.fetch(:target_attributes, []))

        @parameters
      end

      private

        def add_working_zone_attribute_to_group_parameters(group_attributes)
          group_attributes.each do |gp_attrs|
            add_working_zone_attribute_to_parameters(gp_attrs[:targets_attributes])
          end
        end

        def add_working_zone_attribute_to_parameters(target_attributes)
          target_attributes.each do |target_attrs|
            # We don't manually calculate shape of product as it is later calculated by Procedo
            # An empty shape is enought for Procedo to work correctly
            target_attrs[:working_zone] = Charta.empty_geometry
          end
        end
    end
  end
end
