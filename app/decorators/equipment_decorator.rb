class EquipmentDecorator < Draper::Decorator
  delegate_all

  def hour_counter?
    object
      .variant
      .nature
      .decorate
      .hour_counter?
  end

  def hour_counter_present?
    !hour_counter.nil?
  end

  def human_hour_counter
    hour_counter
  end

  private

  def hour_counter
    hour_counter_product_reading = object
                                     .readings
                                     .find_by(indicator_name: :hour_counter)

    return nil if hour_counter_product_reading.nil?

    hour_counter_product_reading.value
  end
end
