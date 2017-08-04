require 'test_helper'

class ProductNatureVariantValuingTest < ActiveSupport::TestCase
  test_model_actions
  def setup
    @valuing = ProductNatureVariantValuing.new(amount: 23.56, average_cost_amount: 35.678, variant_id: 1)
  end

  static_value_1 = {
    unitary_price: 15,
    quantity_action: 200,
    quantity_entry: 200,
    quantity_new: 0
  }

  static_value_2 = {
    unitary_price: 15,
    quantity_action: 200,
    quantity_entry: 200,
    quantity_new: 350
  }

  # test 'valid variant_id' do
  #   refute_nil ProductNatureVariant.find(@valuing.variant_id)
  #   assert ProductNatureVariant.find(static_value_2[:variant_id])
  # end

  test "invalid without amount / average_cost_amount" do
    @valuing.amount = nil
    refute @valuing.valid?, 'valuing is valid without amount'
    assert_not_nil @valuing.errors[:amount], 'no validation error for amount present'
    @valuing.average_cost_amount = nil
    refute @valuing.valid?, 'valuing is valid without amount'
    assert_not_nil @valuing.errors[:average_cost_amount], 'no validation error for average_cost_amount present'
  end

  test "method calculate_first_entrance when current_stock == 0" do
    variant = product_nature_variants(:product_nature_variants_001)
    refute_nil ProductNatureVariantValuing.calculate_first_entrance(static_value_1[:unitary_price], static_value_1[:quantity_action], static_value_1[:quantity_new], variant.id)
    assert ProductNatureVariantValuing.calculate_first_entrance(static_value_1[:unitary_price], static_value_1[:quantity_action], static_value_1[:quantity_new], variant.id)
    # valuing = product_nature_variant_valuings(:product_nature_variant_valuings_001)
    # test when the stock == 0
    # ProductNatureVariantValuing.calculate_first_entrance(static_value_2[:unitary_price], static_value_1[:quantity_new], static_value_2[:quantity_action], variant.id)
    # valuing = ProductNatureVariantValuing.last
    # assert_equal valuing.amount, 3000
    # assert_equal valuing.average_cost_amount, 15
    # # when current_stock >= 0
    # ProductNatureVariantValuing.calculate_first_entrance(static_value_2[:unitary_price], static_value_2[:quantity_new], static_value_2[:quantity_action], variant.id)
    # valuing = ProductNatureVariantValuing.last
    # assert_equal valuing.amount, 3000
    # assert_equal valuing.average_cost_amount, 8
    # test when the stock <= 0
    # ProductNatureVariantValuing.calculate_first_entrance(static_value_2[:unitary_price], static_value_1[:quantity_new], static_value_2[:quantity_action], variant.id)
    # valuing = ProductNatureVariantValuing.last
    # refute valuing.amount, 3000
  end

  test "method calculate_output" do
    variant = product_nature_variants(:product_nature_variants_001)
    # old_valuing = product_nature_variant_valuings(:product_nature_variant_valuings_003)

    # assert_equal old_valuing.amount, 100.34
    # valuing = ProductNatureVariantValuing.calculate_output(static_value_1[:unitary_price], static_value_1[:quantity_action], static_value_2[:quantity_new], old_valuing.variant_id)
    # assert_equal valuing.amount, 3100.34
    # # assert_equal valuing.average_cost_amount, 0.7267
    refute_nil ProductNatureVariantValuing.calculate_output(static_value_1[:unitary_price], static_value_1[:quantity_action], static_value_1[:quantity_new], variant.id)
    assert ProductNatureVariantValuing.calculate_output(static_value_1[:unitary_price], static_value_1[:quantity_action], static_value_1[:quantity_new], variant.id)
  end

  test "method calculate_input" do
    variant = product_nature_variants(:product_nature_variants_001)
    refute_nil ProductNatureVariantValuing.calculate_input(static_value_1[:unitary_price], static_value_1[:quantity_action], variant.id)
    assert ProductNatureVariantValuing.calculate_input(static_value_1[:unitary_price], static_value_1[:quantity_action], variant.id)
  end

  test "method calculate_inventory" do
    variant = product_nature_variants(:product_nature_variants_001)
    refute_nil ProductNatureVariantValuing.calculate_inventory(static_value_1[:quantity_entry], variant.id)
    assert ProductNatureVariantValuing.calculate_inventory(static_value_1[:quantity_entry], variant.id)
  end
end
