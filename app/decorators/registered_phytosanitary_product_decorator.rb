class RegisteredPhytosanitaryProductDecorator < Draper::Decorator
  delegate_all

  def in_field_reentry_delay
    return unless object.in_field_reentry_delay
    if object.in_field_reentry_delay.in_full(:hour) == 6
      "#{object.in_field_reentry_delay.in_full(:hour)} h (8 h #{:if_closed_environment.tl})"
    else
      "#{object.in_field_reentry_delay.in_full(:hour)} h"
    end
  end
end
