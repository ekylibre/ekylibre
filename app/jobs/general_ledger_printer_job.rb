class GeneralLedgerPrinterJob < ApplicationJob
  class InvalidFormatError < StandardError; end
  queue_as :default
  include Rails.application.routes.url_helpers

  # format csv / xcsv
  def perform(template, extension, csv_options, perform_as:, **dataset_params)
    begin
      printer = Printers::GeneralLedgerPrinter.new(template: template, **dataset_params)
      csv_string = CSV.generate(csv_options) do |csv|
        printer.run_csv(csv)
      end

      document = Document.new(
        nature: template.nature,
        key: printer.key,
        name: printer.document_name,
        template: template
      )
      document.attach_file(csv_string, filename: "#{printer.document_name}.#{extension}")
      document.save!

      perform_as.notifications.create!(success_notification_params(document.id))
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
