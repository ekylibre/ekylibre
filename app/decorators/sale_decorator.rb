class SaleDecorator < Draper::Decorator
  delegate_all

  def invoice_address
    object.address || object.client.default_mail_address
  end

  def delivery_address
    object.delivery_address || invoice_address
  end

  def has_same_delivery_address?
    delivery_address == invoice_address
  end
end
