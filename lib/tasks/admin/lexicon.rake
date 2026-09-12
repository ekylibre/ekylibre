namespace :admin do
  namespace :lexicon do
    desc 'Run lexicon action (download/activate/remove) — called from admin UI, tracks status in Redis'
    task run: :environment do
      redis_key = 'ekylibre:admin:lexicon'
      action    = ENV['LEX_ACTION'].to_s
      version   = ENV['LEX_VERSION'].to_s
      keep      = ENV['LEX_KEEP'].to_s == 'true'

      set_status = lambda do |status, message|
        Sidekiq.redis do |r|
          r.hset(redis_key, 'status', status, 'message', message.to_s,
                             'action', action, 'version', version)
        end
      end

      begin
        case action
        when 'download'
          set_status.call('running', "Téléchargement de la version #{version}...")
          Ekylibre::Lexicon.download(version)
          set_status.call('done', "Version #{version} téléchargée.")
        when 'activate'
          set_status.call('running', "Activation de la version #{version}...")
          Ekylibre::Lexicon.activate(version, keep)
          set_status.call('done', "Version #{version} activée.")
        when 'remove'
          set_status.call('running', "Suppression de la version #{version}...")
          Ekylibre::Lexicon.remove(version)
          set_status.call('done', "Version #{version} supprimée.")
        else
          raise "Unknown lexicon action: #{action}"
        end
      rescue SystemExit
        # Ekylibre::Lexicon#error calls exit(false) on failure — surface as error
        set_status.call('error', "Erreur lors de l'action '#{action}' sur la version #{version} (voir log/lexicon.log)")
        raise
      rescue StandardError => e
        set_status.call('error', "Erreur : #{e.message}")
        raise
      end
    end
  end
end
