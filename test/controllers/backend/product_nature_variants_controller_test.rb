require 'test_helper'

module Backend
  class ProductNatureVariantsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions last_purchase_item: :show, quantifiers: { format: :json, mode: :show }, except: %i[show edit update storage_detail]

    test 'update and maaid number attribution' do
      variant = create :phytosanitary_variant
      phyto = RegisteredPhytosanitaryProduct.find(7200298)

      assert_nil variant.france_maaid
      assert_nil variant.reference_name
      assert_nil variant.imported_from

      patch :update, id: variant.id, phyto_product_id: phyto.id, product_nature_variant: variant.attributes

      variant.reload
      assert_equal variant.france_maaid, phyto.france_maaid
      assert_equal variant.reference_name, phyto.reference_name
      assert_equal variant.imported_from, 'Lexicon'
    end
  end
end
