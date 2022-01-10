require 'test_helper'

module Backend
  class ProductNatureVariantsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions last_purchase_item: :show, quantifiers: { format: :json, mode: :show },
                                except: %i[show edit update storage_detail new create compatible_varieties duplicate]

    test 'update and maaid number attribution' do
      variant = create :phytosanitary_variant
      phyto = RegisteredPhytosanitaryProduct.find(7200298)

      assert_nil variant.france_maaid
      assert_nil variant.reference_name
      assert_nil variant.imported_from

      patch :update, params: {
        id: variant.id,
        phyto_product_id: phyto.id,
        product_nature_variant: crush_hash(variant.attributes)
      }

      variant.reload
      assert_equal phyto.france_maaid, variant.france_maaid
      assert_equal phyto.reference_name, variant.reference_name
      assert_equal 'Lexicon', variant.imported_from
    end

    test '#duplicate' do
      variant = create :product_nature_variant

      post :duplicate, params: { id: variant.id }

      new_variant = ProductNatureVariant.order(created_at: :desc).first
      assert_equal "#{variant.name} (1)", new_variant.name
      assert_redirected_to edit_backend_product_nature_variant_url(new_variant)
    end

    private def crush_hash(hash)
      hash.compact.transform_values { |v| v.is_a?(Hash) ? crush_hash(v) : v }
    end
  end
end
