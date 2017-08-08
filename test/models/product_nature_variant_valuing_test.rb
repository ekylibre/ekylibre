require 'test_helper'

class ProductNatureVariantValuingTest < ActiveSupport::TestCase
  test_model_actions
  def setup
    @valuing = ProductNatureVariantValuing.create!(amount: 100, average_cost_amount: 5, variant_id: 1)

  end

  static_value_1 = {
    unitary_price: 15,
    quantity_action: 10,
    quantity_entry: 50,
    quantity_new: 50
  }

  test "invalid without amount / average_cost_amount" do
    @valuing.amount = nil
    refute @valuing.valid?, 'valuing is valid without amount'
    assert_not_nil @valuing.errors[:amount], 'no validation error for amount present'
    @valuing.average_cost_amount = nil
    refute @valuing.valid?, 'valuing is valid without amount'
    assert_not_nil @valuing.errors[:average_cost_amount], 'no validation error for average_cost_amount present'
  end

  test 'create' do
  assert @valuing.save
  end

  test "method calculate_first_entrance" do
    refute_nil ProductNatureVariantValuing.calculate_first_entrance(static_value_1[:unitary_price], static_value_1[:quantity_action], static_value_1[:quantity_new], variant_1.id)
    assert ProductNatureVariantValuing.calculate_first_entrance(static_value_1[:unitary_price], static_value_1[:quantity_action], static_value_1[:quantity_new], variant_1.id)

    valuing = ProductNatureVariantValuing.calculate_first_entrance(static_value_1[:unitary_price], static_value_1[:quantity_new], static_value_1[:quantity_action], variant_7.id)
    assert_equal valuing.amount, 150
    assert_equal valuing.average_cost_amount, 3
  end

  test "method calculate_output" do
    assert_equal @valuing.amount, 100
    valuing = ProductNatureVariantValuing.calculate_output(static_value_1[:unitary_price], static_value_1[:quantity_new], static_value_1[:quantity_action], @valuing.variant_id)
    assert_equal valuing.amount, 250
    assert_equal valuing.average_cost_amount, 5
    refute_nil ProductNatureVariantValuing.calculate_output(static_value_1[:unitary_price], static_value_1[:quantity_new], static_value_1[:quantity_action], @valuing.variant_id)
    assert ProductNatureVariantValuing.calculate_output(static_value_1[:unitary_price], static_value_1[:quantity_new], static_value_1[:quantity_action], @valuing.variant_id)
  end

  test "method calculate_input" do
    # self.calculate_input(quantity_new, quantity_action, variant_id)
    valuing = ProductNatureVariantValuing.calculate_input(static_value_1[:quantity_new], static_value_1[:quantity_action], @valuing.variant_id)
    assert_equal valuing.amount, 50
    assert_equal valuing.average_cost_amount, 1
    refute_nil ProductNatureVariantValuing.calculate_input(static_value_1[:quantity_new], static_value_1[:quantity_action], @valuing.variant_id)
    assert ProductNatureVariantValuing.calculate_input(static_value_1[:quantity_new], static_value_1[:quantity_action], @valuing.variant_id)
  end

  test "method calculate_inventory" do
    # self.calculate_inventory(quantity_entry, variant_id)
    valuing = ProductNatureVariantValuing.calculate_inventory(static_value_1[:quantity_entry], @valuing.variant_id)
    assert_equal valuing.amount, 250
    assert_equal valuing.average_cost_amount, 5
    refute_nil ProductNatureVariantValuing.calculate_inventory(static_value_1[:quantity_entry], @valuing.variant_id)
    assert ProductNatureVariantValuing.calculate_inventory(static_value_1[:quantity_entry], @valuing.variant_id)
  end
end
