# frozen_string_literal: true

class EquipmentDecorator < ProductDecorator
  delegate_all

  def hour_counter_present?
    !object.hour_counter.nil? && !object.hour_counter.value.to_f.zero?
  end

  def human_hour_counter(at: Time.now)
    object.hour_counter(at: at).round(1).l(precision: 1)
  end

end
