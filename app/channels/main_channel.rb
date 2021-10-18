# frozen_string_literal: true

class MainChannel < ApplicationCable::Channel
  def subscribed
    stream_from "main_#{params[:roomId]}"
  end
end
