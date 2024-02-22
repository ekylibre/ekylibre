# frozen_string_literal: true

class SaleExportMailer < ActionMailer::Base
  def notify_client(sale, document, current_user)
    attachments[document.file_file_name] = File.read(document.file.path)

    locales_values = {
      number: sale.number,
      client_full_name: sale.client.full_name,
      current_user_name: current_user.full_name
    }

    if sale.state == 'invoice'
      mail(
        from: current_user.email,
        to: sale.client.default_email_address.coordinate,
        cc: current_user.email,
        subject: I18n.t('mailers.sale_export.notify_invoice_subject', locales_values),
        body: I18n.t('mailers.sale_export.notify_invoice', locales_values)
      )
    else
      mail(
        from: current_user.email,
        to: sale.client.default_email_address.coordinate,
        cc: current_user.email,
        subject: I18n.t('mailers.sale_export.notify_estimate_subject', locales_values),
        body: I18n.t('mailers.sale_export.notify_estimate', locales_values)
      )
    end
  end
end
