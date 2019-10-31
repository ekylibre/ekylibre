class ClosingDocumentExportJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(financial_year, nature, key, user, params = {})
      begin
        if nature == 'income_statement'
          # puts nature.inspect.red
          r = IncomeStatementPrinter.new(financial_year: financial_year, key: key, document_nature: nature, params: params)
        elsif nature == 'balance_sheet'
          r = BalanceSheetPrinter.new(financial_year: financial_year, key: key, document_nature: nature, params: params)
        elsif nature == 'short_balance_sheet'
          r = ShortBalanceSheetPrinter.new(financial_year: financial_year, key: key, document_nature: nature, params: params)
        end

        file_path = r.run_pdf
        document = Document.find_by(key: key)

        notification = user.notifications.build(valid_generation_notification_params(file_path, key, document.id))
      rescue => error
        Rails.logger.error $!
        Rails.logger.error $!.backtrace.join("\n")
        ExceptionNotifier.notify_exception($!, data: { message: error })
        notification = user.notifications.build(error_generation_notification_params(key, nature, error.message))
      end
      notification.save
  end

end
