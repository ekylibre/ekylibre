# frozen_string_literal: true

module Interventions
  class TargetsAttributesBuilder
    GROUP_PARAMETER_REF_NAME = 'zone'

    def initialize(target_parameter, products, at:)
      @target_parameter = target_parameter
      @products = products
      @at = at
    end

    def products_matching_to_filter
      Product.of_expression(target_parameter.filter).merge(products)
    end

    def available_products
      Product.at(at).merge(products)
    end

    def matching_products
      products_matching_to_filter.merge(available_products)
    end

    def attributes
      return {} if matching_products.blank?

      targets_options = matching_products.map do  |product|
        {
          reference_name: target_parameter.name,
          product_id: product.id,
          working_zone: product.shape&.to_geojson
        }
      end

      {
        targets_attributes: targets_options,
        group_parameters_attributes: targets_options.map do |target|
          { reference_name:  GROUP_PARAMETER_REF_NAME, targets_attributes: [target] }
        end
      }
    end

    private

      attr_reader :target_parameter, :products, :at
  end
end
