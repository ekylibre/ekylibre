# frozen_string_literal: true

class SaleExportMailer < ActionMailer::Base
  include Templatable
  prepend_view_path EmailTemplate.resolver
  default from: "#{Entity.of_company.full_name} <#{ENV['MAILER_SENDER']}>"

  before_action { @sale = params[:sale]
                  @document = params[:document]
                  @current_user = params[:current_user]}

  before_action { @email_values = {
      'invoice_number' => @sale.number,
      'client_full_name' => @sale.client.full_name,
      'current_user_name' => @current_user.full_name,
      'current_user_email' => @current_user.email,
      'entity_full_name' => Entity.of_company.full_name
    }
  }

  after_action :set_send_at_to_sale

  def notify_client
    attachments[@document.file_file_name] = File.read(@document.file.path)

    # build and send email
    # grab body from EmailTemplate model and subject from email_templates.yml
    mail(
      reply_to: full_from(@current_user),
      to: @sale.client.default_email_address.coordinate,
      cc: @current_user.email,
      subject: I18n.t('email_templates.sale.subject', { entity_full_name: @email_values['entity_full_name'], invoice_number: @email_values['invoice_number'] })
    )
  end

  def notify_unpaid_sale
    attachments[@document.file_file_name] = File.read(@document.file.path)

    # build and send email
    # grab body from EmailTemplate model and subject from email_templates.yml
    mail(
      reply_to: full_from(@current_user),
      to: @sale.client.default_email_address.coordinate,
      cc: @current_user.email,
      subject: I18n.t('email_templates.unpaid_sale.subject', { entity_full_name: @email_values['entity_full_name'], invoice_number: @email_values['invoice_number'] })
    )
  end

  def liquid_assigns
    @email_values
  end

  private

    def set_send_at_to_sale
      # set last_email_at to sale
      @sale.update_column(:last_email_at, Time.now)
    end
end
