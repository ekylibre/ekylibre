require 'test_helper'

module Backend
  class RegisteredPhytosanitaryProductsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures

    setup do
      @land_parcel = create :lemon_land_parcel, :organic, born_at: DateTime.new(2018, 1, 1)
      phyto_references = { copless: '2000087_copless', award: '2190613_award', sultan: '2000003_sultan', zebra: '2000085_zebra' }
      phyto_references.each { |name, ref| instance_variable_set "@#{name}", create(:phytosanitary_product, variant: ProductNatureVariant.find_by_reference_name(ref)) }
      @award_usage = RegisteredPhytosanitaryUsage.find('20180109110633214028')
      user_sign_in
    end

    test 'get_products_infos checks that products are allowed for organic usage if an organic cultivation is selected' do
      get :get_products_infos,
          products_data: { '0' => { product_id: @copless.id.to_s, usage_id: '' }, '1' => { product_id: @award.id.to_s.to_s, usage_id: '' } },
          targets_data: { '0' => { id: @land_parcel.id.to_s } },
          format: :json

      json = JSON.parse(response.body)

      refute_includes json[@copless.id.to_s]['messages']['product'], :not_allowed_for_organic_farming.tl
      assert_includes json[@copless.id.to_s]['allowed_mentions'], 'organic-usage'

      assert_includes json[@award.id.to_s]['messages']['product'], :not_allowed_for_organic_farming.tl
      refute_includes json[@award.id.to_s]['allowed_mentions'], 'organic-usage'
    end

    test 'get_products_infos forbids every products if one of them belongs to mix_category_code 5' do
      get :get_products_infos,
          products_data: { '0' => { product_id: @copless.id.to_s, usage_id: '' }, '1' => { product_id: @award.id.to_s.to_s, usage_id: '' } },
          format: :json

      json = JSON.parse(response.body)

      assert_includes json[@copless.id.to_s]['messages']['product'], :cannot_be_mixed_with_any_product.tl
      assert_includes json[@award.id.to_s]['messages']['product'], :cannot_be_mixed_with.tl(phyto: @copless.name)
    end

    test 'get_products_infos forbids every products if one of the usages selected has an untreated_buffer_aquatic >= 100 m' do
      get :get_products_infos,
          products_data: { '0' => { product_id: @copless.id.to_s, usage_id: '' }, '1' => { product_id: @award.id.to_s.to_s, usage_id: @award_usage.id.to_s } },
          format: :json

      json = JSON.parse(response.body)

      znt_warning = :substances_mixing_not_allowed_due_to_znt_buffer.tl(usage: @award_usage.crop_label_fra, phyto: @award.name)

      assert_includes json[@copless.id.to_s]['messages']['product'], znt_warning
      assert_includes json[@award.id.to_s]['messages']['product'], znt_warning
    end

    test 'get_products_infos allows products mixing as long as they do not share the same mix_category_code' do
      get :get_products_infos,
          products_data: { '0' => { product_id: @award.id.to_s, usage_id: '' }, '1' => { product_id: @sultan.id.to_s.to_s, usage_id: '' } },
          format: :json

      json = JSON.parse(response.body)

      assert_empty json[@award.id.to_s]['messages']['product']
      assert_empty json[@sultan.id.to_s]['messages']['product']
    end

    test 'get_products_infos forbids products mixing if they share the same mix_category_code' do
      get :get_products_infos,
          products_data: { '0' => { product_id: @zebra.id.to_s, usage_id: '' }, '1' => { product_id: @sultan.id.to_s.to_s, usage_id: '' } },
          format: :json

      json = JSON.parse(response.body)

      assert_includes json[@zebra.id.to_s]['messages']['product'], :cannot_be_mixed_with.tl(phyto: @sultan.name)
      assert_includes json[@sultan.id.to_s]['messages']['product'], :cannot_be_mixed_with.tl(phyto: @zebra.name)
    end

    private

      def user_sign_in
        user = User.find_by(administrator: true)
        sign_in(user)
      end
  end
end
