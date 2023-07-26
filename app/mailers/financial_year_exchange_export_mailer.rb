# frozen_string_literal: true

class FinancialYearExchangeExportMailer < ActionMailer::Base
  def notify_accountant(exchange, current_user, file, zipname)
    attachments[zipname] = File.read(file)

    locales_values = {
      name: Entity.of_company.full_name,
      current_user_name: current_user.full_name,
      exchange_name: exchange.name,
      accountant_full_name: exchange.accountant.full_name,
      exchange_format: exchange.format,
      financial_year_name: exchange.financial_year.name,
      started_on: exchange.started_on.l,
      stopped_on: exchange.stopped_on.l,
      help_doc_url: "https://doc.ekylibre.com/fr/chapitre5/#echanges"
    }

    mail(
      from: current_user.email,
      to: exchange.accountant_email,
      subject: I18n.t('mailers.financial_year_exchange_export.notify_accountant_subject', locales_values),
      body: I18n.t('mailers.financial_year_exchange_export.notify_accountant', locales_values)
    )
  end
end
