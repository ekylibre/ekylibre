class ProductDecorator < Draper::Decorator
  delegate_all

  def land_parcel?
    object.is_a?(LandParcel)
  end

  def not_worker_or_equipment?
    !object.is_a?(Worker) && !object.is_a?(Equipment)
  end
end
