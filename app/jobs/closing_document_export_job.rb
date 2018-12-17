class ClosingDocumentExportJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(financial_year, nature, user)
      begin
        if nature == 'income_statement'
          r = IncomeStatementPrinter.initialize()
        elsif nature == 'balance_sheet'
          r = BalanceSheetPrinter.initialize()
        end

        report_path = r.run_pdf

        file_path = Ekylibre::Tenant.private_directory.join('tmp', "#{filename}")
        FileUtils.mkdir_p(file_path.dirname)


        document = Document.create!(nature: nature, key: "#{Time.now.to_i}-#{filename}", name: filename, file: File.open(file_path))
        notification = user.notifications.build(valid_generation_notification_params(file_path, filename, document.id))
      rescue => error
        Rails.logger.error $!
        Rails.logger.error $!.backtrace.join("\n")
        ExceptionNotifier.notify_exception($!, data: { message: error })
        notification = user.notifications.build(error_generation_notification_params(filename, nature, error.message))
      end
      notification.save
  end

end
