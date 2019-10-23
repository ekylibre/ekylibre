class CentralizingJournalExportJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(document_nature, key, financial_year, user)
    begin
      journal_printer = CentralizingJournalPrinter.new(document_nature: document_nature, key: key, financial_year: financial_year)
      file_path = journal_printer.run_pdf
      document = Document.find_by(key: key)
      notification = user.notifications.build(valid_generation_notification_params(file_path, key, document.id))
    rescue => error
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      ExceptionNotifier.notify_exception($!, data: { message: error })
      notification = user.notifications.build(error_generation_notification_params(key, 'general_journal', error.message))
    end
    notification.save
  end
end
