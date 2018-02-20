class ProductDecorator < Draper::Decorator
  delegate_all

  def land_parcel?
    object.is_a?(LandParcel)
  end
end
