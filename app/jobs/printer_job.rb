class PrinterJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  protected

    def perform(printer_class, *args, template:, perform_as:, **options)
      begin
        generator = Ekylibre::DocumentManagement::DocumentGenerator.build
        archiver = Ekylibre::DocumentManagement::DocumentArchiver.build

        printer = printer_class.constantize.new(*args, template: template, **options)
        pdf_data = generator.generate_pdf(template: template, printer: printer)

        document = archiver.archive_document(pdf_content: pdf_data, template: template, key: printer.key, name: printer.document_name)

        perform_as.notifications.create!(success_notification_params(document.id))

        pdf_data
      rescue StandardError => error
        Rails.logger.error error
        Rails.logger.error error.backtrace.join("\n")
        ExceptionNotifier.notify_exception(error, data: { message: error })
        perform_as.notifications.create!(error_notification_params(error.message))
      end
    end

  private

    def error_notification_params(error)
      {
        message: 'error_during_file_generation',
        level: :error,
        target_type: 'Document',
        # La route backend_export_path pointait sur la page Exports, supprimée
        # avec les agrégateurs. La notification d'erreur renvoie désormais vers
        # la liste des documents, seul endroit qui ait encore du sens.
        target_url: backend_documents_path,
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
