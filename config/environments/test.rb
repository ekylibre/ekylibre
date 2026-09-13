Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  # config.action_mailer.perform_caching = false

  # Store uploaded files on the local file system in a temporary directory
  config.active_storage.service = :test

  # Rails 6 vérifie au démarrage des tests que le schéma est à jour, et recharge
  # `db/structure.sql` s'il juge des migrations en attente. Le contrôle n'a pas
  # de sens ici : avec Apartment, chaque tenant a son propre schéma PostgreSQL,
  # et c'est `Ekylibre::Testing::Helper` qui les construit — la base de test ne
  # porte d'ailleurs aucune table `schema_migrations`, ni dans `public` ni dans
  # les tenants. Laisser Rails « maintenir » le schéma reviendrait à défaire ce
  # que le harnais vient de bâtir.
  config.active_record.maintain_test_schema = false

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :silence

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # L'adaptateur de file d'attente est `sidekiq` pour l'application
  # (config/application.rb). Jusqu'à Rails 7.1, `ActiveJob::TestHelper` le
  # remplaçait d'office par l'adaptateur de test au démarrage de chaque test ;
  # depuis la 7.2 il ne le fait plus que si aucun adaptateur n'est déclaré, si
  # bien que les travaux partaient réellement vers Redis et que
  # `perform_enqueued_jobs` n'exécutait plus rien. On déclare donc ici
  # l'adaptateur que le harnais posait auparavant.
  config.active_job.queue_adapter = :test

  # Identité de signature GPG de la suite. `SignatureManager` lit `GPG_EMAIL`
  # dans l'environnement ; en test cette valeur ne doit jamais venir d'ailleurs :
  #   - vide, la signature refuse de s'exécuter (c'était le cas sur la CI) ;
  #   - pointant une identité réelle — `docker/dev/.env` déclare
  #     `support@ekylibre.com` — la clé est absente du trousseau du conteneur et
  #     quatre tests comptables tombent selon la machine.
  # La clé de test (« Should not be trusted… ») est la seule présente dans les
  # images de développement et importée par le workflow de CI. On la force, pour
  # que la suite ne puisse pas non plus signer avec une clé de production.
  ENV['GPG_EMAIL'] = 'do-not-trust-key@ekylibre.com'
end
