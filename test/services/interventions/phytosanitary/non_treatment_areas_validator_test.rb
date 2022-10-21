require 'test_helper'

module Interventions
  module Phytosanitary
    class NonTreatmentAreasValidatorTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
      test 'get_products_infos forbids a product if its selected usage has an untreated_buffer_aquatic and working zones overlap at least one buffered water zone' do
        target = create :lemon_land_parcel, :organic, born_at: DateTime.new(2018, 1, 1)
        # shape near GAEC JOULIN Farm and the Bruant
        shape = Charta.new_geometry("SRID=4326;Polygon ((-0.7835698127746582 45.83066819629935, -0.7841813564300537 45.830862562911996, -0.7846426963806152 45.830298150295135, -0.7839131355285645 45.83011125743876, -0.7835698127746582 45.83066819629935))")
        area = Measure.new(shape.area, :square_meter)
        product = create(:phytosanitary_product, variant: ProductNatureVariant.find_by_reference_name('2190613_award'))
        phyto = product.phytosanitary_product
        usage = RegisteredPhytosanitaryUsage.find('20210727175041473315')

        targets_zone = [::Interventions::Phytosanitary::Models::TargetZone.new(target, shape, area)]
        products_usages = [::Interventions::Phytosanitary::Models::ProductWithUsage.new(product, phyto, usage, 1.in(:population), nil)]

        validator = ::Interventions::Phytosanitary::NonTreatmentAreasValidator.new(targets_zone: targets_zone)
        result = validator.validate(products_usages)

        assert_equal :forbidden, result.product_vote(product)
        assert_equal [:working_zone_overlaps_nta.tl], result.product_messages(product)
        assert_empty RegisteredHydrographicItem.buffer_intersecting(1, shape)
      end
    end
  end
end
