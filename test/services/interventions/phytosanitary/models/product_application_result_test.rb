require 'test_helper'

module Interventions
  module Phytosanitary
    module Models
      class ProductApplicationResultTest < Ekylibre::Testing::ApplicationTestCase
        setup do
          @product = create(:phytosanitary_product)
          @product2 = create(:phytosanitary_product, variant: @product.variant)

          @result = ProductApplicationResult.new
        end

        test 'it returns unknown if the product does not have a registered phyto -- no maaid' do
          stub_many @result, maaid_for: None() do
            assert_equal :unknown, @result.product_vote(@product)
            assert_equal 'Maaid not provided', @result.product_messages(@product).first
          end
        end

        test 'it returns the same message or vote for two different products having the same maaid' do
          stub_many @result, maaid_for: Some('424242') do
            @result.vote_forbidden(@product, 'This is not allowed')

            assert_equal :forbidden, @result.product_vote(@product)
            assert_equal :forbidden, @result.product_vote(@product2)

            assert_equal 'This is not allowed', @result.product_messages(@product).first
            assert_equal 'This is not allowed', @result.product_messages(@product2).first
          end
        end
      end
    end
  end
end
