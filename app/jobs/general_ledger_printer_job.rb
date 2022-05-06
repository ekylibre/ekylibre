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

      document = Document.create!(
        nature: template.nature,
        key: printer.key,
        name: printer.document_name,
        file: StringIO.new(csv_string),
        file_file_name: "#{printer.document_name}.#{extension}",
        template: template
      )

      perform_as.notifications.create!(success_notification_params(document.id))
    rescue StandardError => error
      Rails.logger.error error
      Rails.logger.error error.backtrace.join("\n")
      ExceptionNotifier.notify_exception(error, data: { message: error })
      ElasticAPM.report(error)
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
