class RegisteredPhytosanitaryRiskDecorator < Draper::Decorator
  delegate_all

  def symbol_name
    ActionController::Base.helpers.image_tag("plant_medicines/#{object.symbol_name}.svg", class: 'list-picto')
  end
end
