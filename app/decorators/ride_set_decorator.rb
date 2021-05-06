# frozen_string_literal: true

class RideSetDecorator < Draper::Decorator
  delegate_all

  def duration
    duration_to_strftime(object.duration)
  end

  def sleep_duration
    duration_to_strftime(object.sleep_duration)
  end

  private

    def duration_to_strftime(duration)
      return if duration.nil?

      Time.at(duration.to_i).utc.strftime("%Hh%Mmn%Ss")
    end
end
