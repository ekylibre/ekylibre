class TaxDeclarationJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(financial_year, user)
    begin
      tax_declaration = TaxDeclaration.create!(financial_year: financial_year)
      notification = user.notifications.build(message: 'vat_declaration_generated',
                                              level: :success,
                                              target_url: backend_tax_declaration_path(tax_declaration),
                                              interpolations: {})
    rescue => error
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      ExceptionNotifier.notify_exception($!, data: { message: error })
      notification = user.notifications.build(message: 'error_during_vat_declaration_generation',
                                              level: :error,
                                              target_url: backend_tax_declarations_path,
                                              interpolations: { error_message: error })
    end
    notification.save
  end
end
