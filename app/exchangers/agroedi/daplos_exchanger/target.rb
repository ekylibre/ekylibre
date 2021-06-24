# frozen_string_literal: true

module Agroedi
  class DaplosExchanger < ActiveExchanger::Base
    class Target < DaplosNode
      daplos_parent :intervention

      attr_reader :target_support, :target_production, :reference

      def initialize(*args, &block)
        super
        @reference = intervention.procedure.parameters_of_type(:target).first
        @target_support = intervention.production_support
        @target_production = intervention.production
      end

      def uid
        to_attributes.hash
      end

      def to_attributes(json_shape: true)
        geom = target_support.shape
        geom = json_shape ? geom.to_geojson : geom.to_rgeo
        {
          reference_name: @reference.name,
          product_id: target_support.id,
          working_zone: geom
        }
      end
    end
  end
end
