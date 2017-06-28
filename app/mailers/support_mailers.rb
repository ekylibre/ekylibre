class SupportMailers < ActionMailer::Base
  def first_run_errors(message, time)
    @tenant = Ekylibre::Tenant.current
    message = message.read
    message = message.split(',')
    error_time = DateTime.parse(message.first)
    @time = time - error_time
    @progress = message.second
    mail(
      to: 'dev@ekylibre.com',
      subject: "Erreur durant l'import du first-run"
    )
  end
end
