class RegistrationMailer < ActionMailer::Base
  default from: Devise.mailer_sender,
          template_path: 'devise/mailer'

  def approved(approved_user)
    @resource = approved_user
    mail(to: @resource.email,
         subject: t('devise.mailer.registrations.approved.subject'))
  end

  def signed_up(signed_up_user)
    @resource = signed_up_user
    mail(to: User.administrators.pluck(:email),
         subject: t('devise.mailer.registrations.signed_up.subject'))
  end
end
