class PurchaseInvoiceClassifierJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(document_id, vendor, user_id)
    begin
      @document = Document.find(document_id)
      user = User.find(user_id)
      return nil unless @document.present?

      # launch OCR on document to have metadata
      unless @document.metadata[vendor.to_s].present?
        ocr_by_vendor(vendor)
        @document.reload
      end
      # launch Parser on metadata to create purchase
      if @document.metadata[vendor.to_s].present?
        new_purchase_id = parser_by_vendor(vendor)
        if new_purchase_id
          { redirect_to: backend_purchase_invoice_path(id: new_purchase_id) }
        else
          notification = user.notifications.build(error_on_purchase_classification_notification('cannot_transform_purchase_document'))
        end
      else
        notification = user.notifications.build(error_on_purchase_classification_notification('no metadata present on document'))
      end
      notification = user.notifications.build(success_on_purchase_classification_notification(service))
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: e })
      notification = user.notifications.build(error_on_purchase_classification_notification(e.message))
    end
    notification.save
  end

  private

    def ocr_by_vendor(vendor)
      if vendor == 'mindee'
        p = PurchaseInvoices::MindeeOcr.new.post_document_and_parse(@document)
        if p[:status] != :success
          "#{p[:message]} #{p[:status]}"
        end
      end
    end

    def parser_by_vendor(vendor)
      if vendor == 'mindee'
        mindee_parser = PurchaseInvoices::MindeeParser.new(@document.id)
        mindee_parser.parse_and_create_invoice
      end
    end

    # Begin of notifs builder
    def error_on_purchase_classification_notification(error)
      {
        message: 'error_on_purchase_classification',
        level: :error,
        interpolations: {
          error: error
        }
      }
    end

    def success_on_purchase_classification_notification(result)
      {
        message: "success_on_purchase_classification",
        level: :success,
        interpolations: {
          it_count: result[:items_classified]
        }
      }
    end

end
