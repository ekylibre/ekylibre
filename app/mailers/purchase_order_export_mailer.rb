# frozen_string_literal: true

class PurchaseOrderExportMailer < ActionMailer::Base
  def notify_supplier(purchase_order, document, current_user)
    attachments[document.file_file_name] = File.read(document.file.path)

    locales_values = {
      name: Entity.of_company.full_name,
      number: purchase_order.number,
      supplier_name: purchase_order.supplier.full_name,
      current_user_name: current_user.full_name,
      pretax_amount: purchase_order.pretax_amount,
      ordered_at: purchase_order.ordered_at.l
    }

    mail(
      from: current_user.email,
      to: purchase_order.supplier.default_email_address.coordinate,
      cc: current_user.email,
      subject: I18n.t('mailers.purchase_order_export.notify_supplier_subject', locales_values),
      body: I18n.t('mailers.purchase_order_export.notify_supplier', locales_values)
    )
  end
end
