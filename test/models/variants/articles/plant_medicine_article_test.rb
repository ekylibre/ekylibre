require 'test_helper'

module Variants
  module Articles
    class PlantMedicineArticleTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

      test "changing a record's reference to lexicon is not possible if a link to another plant medicine is already established" do
        copless_variant = ProductNatureVariant.find_by_reference_name('2000087_copless')

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
