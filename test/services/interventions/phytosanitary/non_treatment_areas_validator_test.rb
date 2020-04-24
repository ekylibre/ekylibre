require 'test_helper'

module Interventions
  module Phytosanitary
    class NonTreatmentAreasValidatorTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

      test 'get_products_infos forbids a product if its selected usage has an untreated_buffer_aquatic and working zones overlap at least one buffered water zone' do
        target = create :lemon_land_parcel, :organic, born_at: DateTime.new(2018, 1, 1)
        shape = Charta.new_geometry("SRID=4326;Polygon ((-0.6183832883834839 44.49441607768577, -0.6183135509490966 44.49375790909347, -0.6172621250152588 44.49386122674773, -0.6172889471054077 44.49444668999765, -0.6183832883834839 44.49441607768577))")
        product = create(:phytosanitary_product, variant: ProductNatureVariant.find_by_reference_name('2190613_award'))
        phyto = product.phytosanitary_product
        usage = RegisteredPhytosanitaryUsage.find('20180109110633214028')

        targets_and_shape = [::Interventions::Phytosanitary::Models::TargetAndShape.new(target, shape)]
        products_usages = [::Interventions::Phytosanitary::Models::ProductWithUsage.new(product, phyto, usage, 1, 'population')]

        validator = ::Interventions::Phytosanitary::NonTreatmentAreasValidator.new(targets_and_shape: targets_and_shape)
        result = validator.validate(products_usages)

        assert result.votes.has_key?(product)
        assert_includes result.votes[product].map { |v| [v.vote, v.message] }, [:forbidden, :working_zone_overlaps_nta.tl]
        assert_empty RegisteredHydroItem.buffer_intersecting(1, shape)
      end
    end
  end
end
