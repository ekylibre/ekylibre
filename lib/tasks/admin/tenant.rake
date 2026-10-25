namespace :admin do
  namespace :tenant do
    desc 'Create a new tenant with admin user + optional credentials email (tracks progress in Redis)'
    task create: :environment do
      redis_key = Admin::CreateTenantJob::REDIS_KEY

      name     = ENV.fetch('TENANT_NAME')
      email    = ENV.fetch('TENANT_EMAIL', 'admin@ekylibre.org')
      password = ENV['TENANT_PASSWORD'].to_s.presence
      language = ENV.fetch('TENANT_LANGUAGE', 'fra')
      country  = ENV.fetch('TENANT_COUNTRY',  'fr')
      currency = ENV.fetch('TENANT_CURRENCY', 'EUR')
      send_email = ENV['TENANT_SEND_EMAIL'] == '1'

      set_status = lambda do |status, message|
        Sidekiq.redis do |r|
          r.hmset(redis_key, 'status', status, 'message', message.to_s, 'tenant', name.to_s)
        end
      end

      begin
        set_status.call('running', "Création du tenant '#{name}'...")
        Ekylibre::Tenant.create(name)

        generated_password = nil
        Ekylibre::Tenant.switch(name) do
          language_name = Onoma::Language.find(language).try(:name) || 'fra'
          country_name  = Onoma::Country.find(country).try(:name)   || 'fr'
          currency_name = Onoma::Currency.find(currency).try(:name) || 'EUR'
          effective_password = password || SecureRandom.hex(8)
          generated_password = effective_password if password.nil?

          Preference.set! :language, language_name
          Preference.set! :country, country_name
          Preference.set! :currency, currency_name
          Preference.set! :map_measure_srs, 'WGS84'
          Preference.set! :sales_conditions, ''
          ::I18n.locale = language_name.to_sym

          Preference.set! :accounting_system, 'fr_pcga2023'
          Account.load_defaults
          Tax.load_defaults
          Unit.load_defaults
          Sequence.load_defaults
          DocumentTemplate.load_defaults
          MapLayer.load_defaults
          NamingFormatLandParcel.load_defaults
          FinancialYear.create!(
            accounting_system: 'fr_pcga2023',
            started_on: Date.new(Time.zone.now.year, 1, 1),
            stopped_on: Date.new(Time.zone.now.year, 12, 31)
          )
          Journal.load_defaults
          SaleNature.load_defaults
          PurchaseNature.load_defaults

          Entity.create!(
            language: language_name,
            currency: currency_name,
            nature: :organization,
            of_company: true,
            last_name: name.upcase,
            born_at: Date.new(Time.zone.now.year, 1, 1).to_time
          )

          User.create!(
            email: email,
            administrator: true,
            password: effective_password,
            password_confirmation: effective_password,
            first_name: 'Admin',
            last_name: name
          )
        end

        if send_email
          set_status.call('running', "Envoi de l'email de connexion à #{email}...")
          domain = ENV['HOST_DOMAIN_NAME'] || 'ekylibre.localhost'
          url = "https://#{name}.#{domain}/"
          locale = Onoma::Language.find(language).try(:name) || 'eng'
          mail_password = password || generated_password

          begin
            TenantCreationMailer.credentials(
              email: email,
              tenant: name,
              password: mail_password,
              url: url,
              locale: locale
            ).deliver_now
            email_msg = " Email de connexion envoyé à #{email}."
          rescue => e
            Rails.logger.error("TenantCreationMailer failed for tenant=#{name}: #{e.class} #{e.message}")
            email_msg = " (L'envoi de l'email a échoué : #{e.message})"
          end
        else
          email_msg = ''
        end

        final = "Tenant '#{name}' créé avec succès."
        final += " Mot de passe admin : #{generated_password}" if generated_password
        final += email_msg
        set_status.call('done', final)
      rescue => e
        Ekylibre::Tenant.drop(name) if Ekylibre::Tenant.exist?(name)
        set_status.call('error', "Erreur lors de la création : #{e.message}")
        raise
      end
    end
  end
end
