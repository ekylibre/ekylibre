class ReflectInventoryJob < ActiveJob::Base
  queue_as :default

  # Change the number of all the different product
  # Create a notification, with a message
  def perform(inventory, user)
    result = inventory.reflect
    notification = user.notifications.build(notification_params(result, inventory))
    notification.save
  end

  private

  def notification_params(result, inventory)
    {
      message: (result ? :changes_have_been_reflected : :changes_have_not_been_reflected),
      level: (result ? :success : :error),
      target_type: 'Inventory',
      interpolations: {
        inventory_id: inventory.id,
        inventory_name: inventory.name
      }
    }
  end
end
