# frozen_string_literal: true

class FinancialYearExchangeExportMailer < ActionMailer::Base
  def notify_accountant(exchange, current_user, file, zipname)
    attachments[zipname] = File.read(file)

    locales_values = {
      name: Entity.of_company.full_name,
      current_user_name: current_user.full_name,
      exchange_name: exchange.name,
      accountant_full_name: exchange.accountant.full_name
    }

    mail(
      from: current_user.email,
      to: exchange.accountant_email,
      subject: I18n.t('mailers.financial_year_exchange_export.notify_accountant_subject', locales_values),
      body: I18n.t('mailers.financial_year_exchange_export.notify_accountant', locales_values)
    )
  end
end
