class RegistrationMailer < ActionMailer::Base
  default from: Devise.mailer_sender,
    template_path: 'devise/mailer',
    template_name: 'approved'

  def approved(approved_user)
    @resource = approved_user
    mail(to: @resource.email,
         subject: t("devise.mailer.registrations.approved.subject"))
  end
end
