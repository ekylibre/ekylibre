require 'test_helper'

class ReflectInventoryJobTest < ActiveJob::TestCase
  test 'completeness' do
    inventory = Inventory.new(
      name: 'Sample inventory to run now',
      financial_year: FinancialYear.current
    )
    inventory.build_missing_items
    inventory.save!
    assert inventory.items.count > 0, 'No items in inventory'

    user = User.where(locked: false).first
    assert user
    count = user.notifications.count

    ReflectInventoryJob.perform_now(inventory, user)

    assert inventory.reflected, 'Inventory should be reflected'
    assert_equal count + 1, user.notifications.count, 'User should be notified'
  end
end
