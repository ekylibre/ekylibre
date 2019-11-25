class AffairableDecorator < Draper::Decorator
  delegate_all

  def payment_date
    return created_at if object.is_a? Sale

    Maybe(object.try(:paid_at))
      .recover(object.try(:printed_at))
      .or_else(created_at)
  end
end