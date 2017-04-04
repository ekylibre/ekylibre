class ReflectInventoryJob < ActiveJob::Base
  queue_as :default

  def perform(inventory, user)
    result = inventory.reflect
    user.notifications.build(notification_params(result, inventory))
    # if inventory.reflect
    #   user.notifications.build(notification_params(:success, inventory))
    #   # notify_success(:changes_have_been_reflected)
    # else
    #   notify_error(:changes_have_not_been_reflected)
    # end
  end

  private

  def notification_params(result, inventory)
    {
    message: (result ? :changes_have_been_reflected : :changes_have_not_been_reflected),
    level: (result ? :success : :error),
    target_type: "Inventory",
    interpolations: {
        inventory_id: inventory.id,
        inventory_name: inventory.name
      }
    }
  end

  def result_message(result)
    result ? :changes_have_been_reflected : :changes_have_not_been_reflected
  end
end
