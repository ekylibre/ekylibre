require 'test_helper'

module Variants
  module Articles
    class PlantMedicineArticleTest < Ekylibre::Testing::ApplicationTestCase

      test "changing a record's reference to lexicon is not possible if a link to another plant medicine is already established" do
        copless_variant = ProductNatureVariant.find(create(:copless_phytosanitary_variant).id)

        assert copless_variant.update(name: 'Random name')

        cases = [%w[imported_from Nomenclature], %w[reference_name fake_ref], %w[france_maaid 123456]]

        cases.each do |(attribute, value)|
          assert_raise ActiveRecord::RecordInvalid do
            copless_variant.update!(attribute => value)
          end
        end
      end
    end
  end
end
