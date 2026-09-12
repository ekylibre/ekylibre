# frozen_string_literal: true

redis_options = { url: ENV['REDIS_URL'] || "redis://localhost:6379/#{ENV['REDIS_DATABASE_NUMBER'] || 0}" }

# Le préfixe de clés (`REDIS_NAMESPACE`, via redis-namespace) a disparu avec
# sidekiq 7, qui parle à Redis par `redis-client`. La variable n'était définie
# dans aucun environnement — ni `.env`, ni les composes, ni la CI — et la gem
# n'avait pas d'autre consommateur : sa suppression ne déplace aucune clé.

Sidekiq.configure_server do |config|
  config.redis = redis_options

  # `Sidekiq::Middleware::Server::RetryJobs` n'est plus un intergiciel que l'on
  # ajoute à la chaîne depuis sidekiq 6 : la reprise est un réglage de la
  # configuration. Zéro reprise est le comportement que portait la série 4 et il
  # est reconduit tel quel — au prix d'échecs silencieux, voir CLAUDE.md.
  config[:max_retries] = 0
end

Sidekiq.configure_client do |config|
  config.redis = redis_options
end

# `config/schedule.yml` est le chemin que sidekiq-cron 2 lit de lui-même au
# démarrage du serveur (`Sidekiq::Cron::ScheduleLoader`) : le charger ici, à
# l'initialisation, le faisait avant même que Redis soit joignable.
