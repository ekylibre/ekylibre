# frozen_string_literal: true

class TenantCreationMailer < ActionMailer::Base
  default from: Devise.mailer_sender

  def credentials(email:, tenant:, password:, url:, locale: 'eng')
    @tenant = tenant
    @email = email
    @password = password
    @url = url

    I18n.with_locale(locale) do
      mail(to: email,
           subject: t('mailers.tenant_creation_mailer.credentials.subject', tenant: tenant))
    end
  end
end
