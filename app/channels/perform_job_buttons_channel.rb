# frozen_string_literal: true

class PerformJobButtonsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end
end
