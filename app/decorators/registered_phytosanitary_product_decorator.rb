class RegisteredPhytosanitaryProductDecorator < Draper::Decorator
  delegate_all

  def in_field_reentry_delay
    return unless object.in_field_reentry_delay
    if object.in_field_reentry_delay == 6
      "#{object.in_field_reentry_delay} h (8 h #{:if_closed_environment.tl})"
    else
      "#{object.in_field_reentry_delay} h"
    end
  end
end
