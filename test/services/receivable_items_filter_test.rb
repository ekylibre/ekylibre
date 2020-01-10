require 'test_helper'

class ReceivableItemsFilterTest < ActiveSupport::TestCase
  setup do
    @filter = ReceivableItemsFilter.new
  end

  test "Should filter out item with quantity_to_receive == 0" do
    orders = []

    items = []
    3.times do
      i = Minitest::Mock.new
      i.expect :quantity_to_receive, 0
      items << i
    end

    o = Minitest::Mock.new
    o.expect :items, items
    orders << o

    assert_empty @filter.filter(orders)

    assert_mock o
    items.each do |i|
      assert_mock i
    end
  end
end