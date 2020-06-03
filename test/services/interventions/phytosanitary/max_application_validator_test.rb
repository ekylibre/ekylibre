require 'test_helper'

module Interventions
  module Phytosanitary
    class MaxApplicationValidatorTest < Ekylibre::Testing::ApplicationTestCase
      test 'vaidate product_sages' do         
          validator = MaxApplicationValidator.new(targets_and_shape: [Models::TargetAndShape.new(nil, nil)], intervention_stopped_at: DateTime.new(2001,2,3,4,5,6))
          product_usage = Models::ProductWithUsage.new(
            Product.new,
            InterventionParameter::LoggedPhytosanitaryProduct.new,
            RegisteredPhytosanitaryUsage.new(applications_count: 1, applications_frequency: 'P4D'),
            4,
            "test"
          )
          result = validator.validate([product_usage])
          
          assert result
          assert_equal :unknown, result.product_vote(product_usage.product)
      end
    end
  end
end