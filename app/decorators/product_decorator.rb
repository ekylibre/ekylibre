class ProductDecorator < Draper::Decorator
  delegate_all

  def land_parcel?
    object.is_a?(LandParcel)
  end

  def not_worker_or_equipment?
    !object.is_a?(Worker) && !object.is_a?(Equipment)
  end

  def participation?(intervention_id)
    participation = object
                    .intervention_participations
                    .find_by(intervention_id: intervention_id)

    participation.present?
  end

  def no_participation?(intervention_id)
    !participation?(intervention_id)
  end
end
