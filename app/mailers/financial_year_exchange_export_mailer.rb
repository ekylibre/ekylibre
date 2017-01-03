class FinancialYearExchangeExportMailer < ActionMailer::Base
  def notify_accountant(exchange, current_user)
    @resource = exchange
    values = {
      name: Entity.of_company.full_name,
      current_user_name: current_user.full_name,
      link: public_financial_year_exchange_export_url(id: @resource.public_token)
    }
    mail(
      from: current_user.email,
      to: @resource.accountant_email,
      subject: I18n.t('mailers.financial_year_exchange_export.notify_accountant_subject', values),
      body: I18n.t('mailers.financial_year_exchange_export.notify_accountant', values)
    )
  end
end
