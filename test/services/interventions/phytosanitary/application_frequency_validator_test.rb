require 'test_helper'

module Interventions
  module Phytosanitary
    class ApplicationFrequencyValidatorTest < Ekylibre::Testing::ApplicationTestCase
      test "if no targets, all products should be marked as unknown" do
        validator = Interventions::Phytosanitary::ApplicationFrequencyValidator.new(targets_and_shape: [])

        product = Product.new
        product_usages = [Models::ProductWithUsage.new(product, RegisteredPhytosanitaryProduct.new, RegisteredPhytosanitaryUsage.new, 0, "")]
        result = validator.validate(product_usages)

        assert_equal :unknown, result.product_vote(product)
      end

      test "guess_vote" do
        cases = [
          #[usage_params, maaid, phyto, interval_respected, expected_result]
          [nil, nil, nil, nil, :unknown],
          [{}, "8548547", nil, nil, :unknown],
          [{}, "8548547", "", nil, :allowed],
          [{ applications_frequency: ActiveSupport::Duration.parse("P4D") }, "8548547", "", false, :forbidden],
          [{ applications_frequency: ActiveSupport::Duration.parse("P4D") }, "8548547", "", true, :allowed],
          [{ applications_frequency: ActiveSupport::Duration.parse("P4D"), applications_count: 1 }, "8548547", "", true, :allowed]
        ]

        validator = Interventions::Phytosanitary::ApplicationFrequencyValidator.new(targets_and_shape: [])

        cases.each do |usage_params, maaid, phyto, interval_respected, expected|
          product = make_product(france_maaid: maaid, phytosanitary_product: phyto)
          usage = usage_params.nil? ? nil : make_usage(**usage_params)

          product_usage = Models::ProductWithUsage.new(product, phyto, usage, 0, "")

          validator.stub(:interval_respected?, interval_respected) do
            assert_equal expected, validator.guess_vote(product_usage)
          end
        end
      end

      private

        def make_product(france_maaid: nil, phytosanitary_product: nil)
          {
            france_maaid: france_maaid,
            phytosanitary_product: phytosanitary_product
          }.to_struct
        end

        def make_usage(applications_frequency: nil, applications_count: nil)
          {
            applications_frequency: applications_frequency,
            applications_count: applications_count
          }.to_struct
        end
    end
  end
end
