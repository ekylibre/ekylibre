class PurchaseOrderExportJob < ApplicationJob
  class InvalidFormatError < StandardError; end
  queue_as :default
  include Rails.application.routes.url_helpers

  # format csv / fec_txt / fec_xml
  def perform(purchase_order, document, user)
    # send email attached document to supplier or create document in Ekylibre
    begin
      PurchaseOrderExportMailer.notify_supplier(purchase_order, document, user).deliver_now
      user.notifications.create!(valid_generation_notification_params(document.id, purchase_order))
    rescue StandardError => error
      user.notifications.create!(error_generation_notification_params(error.message))
    end
  end

  private def error_generation_notification_params(error)
    {
      message: :error_during_file_generation.tl,
      level: :error,
      interpolations: {
        error_message: error
      }
    }
  end

  private def valid_generation_notification_params(document_id, purchase_order)
    {
      message: :purchase_order_sent_to_supplier.tl,
      level: :success,
      target_type: 'Document',
      target_id: document_id,
      target_url: backend_document_path(document_id),
      interpolations: {
        email: purchase_order.supplier.default_email_address.coordinate,
        number: purchase_order.number
      }
    }
  end

end
