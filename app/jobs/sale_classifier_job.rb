class SaleClassifierJob < ActiveJob::Base
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
      # launch Parser on metadata to create sale
      if @document.metadata[vendor.to_s].present?
        new_sale_id = parser_by_vendor(vendor)
        if new_sale_id
          { redirect_to: backend_sale_path(id: new_sale_id) }
        else
          notification = user.notifications.build(error_on_sale_classification_notification('cannot_transform_sale_document'))
        end
      else
        notification = user.notifications.build(error_on_sale_classification_notification('no metadata present on document'))
      end
      notification = user.notifications.build(success_on_sale_classification_notification)
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: e })
      notification = user.notifications.build(error_on_sale_classification_notification(e.message))
    end
    notification.save
  end

  private

    def ocr_by_vendor(vendor)
      SaleInvoices::MistralOcr.new(vendor).post_document_and_parse(@document)
    end

    def parser_by_vendor(vendor)
      mistral_parser = SaleInvoices::MistralParser.new(vendor, @document.id)
      mistral_parser.parse_and_create_invoice
    end

    # Begin of notifs builder
    def error_on_sale_classification_notification(error)
      {
        message: 'error_on_purchase_classification',
        level: :error,
        interpolations: {
          error: error
        }
      }
    end

    def success_on_sale_classification_notification
      {
        message: "success_on_purchase_classification",
        level: :success,
        interpolations: {
        }
      }
    end

end
