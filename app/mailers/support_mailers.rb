class SupportMailers < ActionMailer::Base
  def first_run_errors(message)
    @tenant = Ekylibre::Tenant.current
    message = message.split(',')
    @time = message.first
    @progress = message.second
    mail(
      to: 'dev@ekylibre.com',
      subject: "Erreur durant l'import du first-run"
    )
  end
end
