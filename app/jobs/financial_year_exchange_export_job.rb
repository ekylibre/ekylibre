class FinancialYearExchangeExportJob < ApplicationJob
  class InvalidFormatError < StandardError; end
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(exchange, format, user, notify_accountant: false)
    zipname = "#{Time.now.to_i}FEC#{exchange.stopped_on.l(format: '%Y%m%d')}.zip"
    begin
      build_zip(exchange, format) do |tempzip|
        if notify_accountant
          FinancialYearExchangeExportMailer.notify_accountant(exchange, user, tempzip, zipname).deliver_now
          user.notifications.create!(accountant_notified_notification_params)
        else
          # TODO: Change nature of doc ?
          document = Document.create!(nature: "exchange_accountancy_file_fr", processable_attachment: false, file: tempzip, name: zipname)
          user.notifications.create!(valid_generation_notification_params(document.id))
        end
      end
    rescue StandardError => error
      user.notifications.create!(error_generation_notification_params(error.message))
    end
  end

  private def get_export(format)
    case format
    when 'csv'
      yield FinancialYearExchanges::CsvExport.new
    when 'fec_txt'
      yield FinancialYearExchanges::FecTxtExport.new
    when 'fec_xml'
      yield FinancialYearExchanges::FecXmlExport.new
    else
      raise InvalidFormatError.new("Format '#{format}' is not supported")
    end
  end

  private def build_zip(exchange, format)
    Tempfile.create do |tempzip|
      Zip::File.open(tempzip, Zip::File::CREATE) do |zipfile|
        get_export(format) do |export|
          export.generate_file(exchange) do |file_path|
            zipfile.add(export.filename(exchange), file_path)
          end
        end
      end
      yield tempzip
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

  private def valid_generation_notification_params(document_id)
    {
      message: :journal_entries_export_file_generated.tl,
      level: :success,
      target_type: 'Document',
      target_id: document_id,
      target_url: backend_document_path(document_id),
      interpolations: {}
    }
  end

  private def accountant_notified_notification_params
    {
      message: :accountant_notified.tl,
      level: :success,
      interpolations: {}
    }
  end
end
