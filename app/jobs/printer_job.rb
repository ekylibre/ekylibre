class PrinterJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  protected

    def perform(printer_class, *args, template:, perform_as:, **options)
      begin
        printer = printer_class.constantize.new(*args, template: template, **options)

        pdf_data = printer.run_pdf

        document = printer.archive_report_template(pdf_data, nature: template.nature, key: printer.key, template: template, document_name: printer.document_name)

        perform_as.notifications.create!(success_notification_params(document.id))

        pdf_data
      rescue StandardError => error
        Rails.logger.error $!
        Rails.logger.error $!.backtrace.join("\n")
        ExceptionNotifier.notify_exception($!, data: { message: error })
        perform_as.notifications.create!(error_notification_params(template.nature, error.message))
      end
    end

  private

    def error_notification_params(id, error)
      {
        message: 'error_during_file_generation',
        level: :error,
        target_type: 'Document',
        target_url: backend_export_path(id),
        interpolations: {
          error_message: error
        }
      }
    end

    def success_notification_params(document_id)
      {
        message: 'file_generated',
        level: :success,
        target_type: 'Document',
        target_url: backend_document_path(document_id),
        interpolations: {}
      }
    end

end
