require 'test_helper'

module Interventions
  module Phytosanitary
    class MaxApplicationValidatorTest < Ekylibre::Testing::ApplicationTestCase
      test 'vaidate product_usages' do
        validator = MaxApplicationValidator.new(targets_and_shape: [Models::TargetAndShape.new(nil, nil)], intervention_stopped_at: DateTime.new(2001, 2, 3, 4, 5, 6))
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

      test 'application is forbidden if we are already at the limit' do
        create :campaign, harvest_year: 2020
        i1 = OpenStruct.new(id: 1)

        # The validator is configured for the creation of an intervention
        validator = MaxApplicationValidator.new(
          targets_and_shape: [Models::TargetAndShape.new(nil, nil)],
          intervention_stopped_at: DateTime.parse("2020-01-02T16:00:00Z"),
          intervention_to_ignore: nil
        )

        product_usage = Models::ProductWithUsage.new(
          Product.new,
          InterventionParameter::LoggedPhytosanitaryProduct.new,
          RegisteredPhytosanitaryUsage.new(applications_count: 1),
          4,
          "test"
        )

        # We are adding an intervention that conflicts with i1
        stub_many validator, select_with_shape_intersecting: [i1], get_interventions_with_same_phyto: [i1] do
          res = validator.validate([product_usage])
          assert_equal :forbidden, res.product_vote(product_usage.product)
        end

      end

      test 'behaves correctly on intervention update' do
        create :campaign, harvest_year: 2020
        i1 = OpenStruct.new(id: 1)
        i2 = OpenStruct.new(id: 2)

        # The validator is configured for the edition of i2
        validator = MaxApplicationValidator.new(
          targets_and_shape: [Models::TargetAndShape.new(nil, nil)],
          intervention_stopped_at: DateTime.parse("2020-01-02T16:00:00Z"),
          intervention_to_ignore: i2
        )

        product_usage = Models::ProductWithUsage.new(
          Product.new,
          InterventionParameter::LoggedPhytosanitaryProduct.new,
          RegisteredPhytosanitaryUsage.new(applications_count: 1),
          4,
          "test"
        )

        # We are editing i2 that was already created despite being 'forbidden'
        stub_many validator, select_with_shape_intersecting: [i1, i2], get_interventions_with_same_phyto: [i1, i2] do
          res = validator.validate([product_usage])
          assert_equal :forbidden, res.product_vote(product_usage.product)
        end

        # we are editing i2 that already exists and we want to add a product that will make the application forbidden as it is used in i1
        stub_many validator, select_with_shape_intersecting: [i1], get_interventions_with_same_phyto: [i1] do
          res = validator.validate([product_usage])
          assert_equal :forbidden, res.product_vote(product_usage.product)
        end
      end
    end
  end
end