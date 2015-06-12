class GolumnsController < ApplicationController
  # Save golumn config in preferences
  def update
    unless params["golumn"].nil?
      begin
        current_user.prefer!("golumn.#{params[:id]}", {version: Backend::BeehiveHelper::FORMAT_VERSION, boxes: boxes}.deep_stringify_keys.to_yaml)
        head :ok
      rescue ActiveRecord::StaleObjectError
        head :locked
      end
    end
  end


  def reset
    if preference = current_user.preferences.find_by(name: "golumn.#{params[:id]}")
      preference.destroy!
    end
    head :ok
  end
end
