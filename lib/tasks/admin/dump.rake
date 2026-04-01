namespace :admin do
  namespace :dump do
    desc 'Dump a tenant archive (called from admin UI, tracks status in Redis)'
    task run: :environment do
      require 'ekylibre/tenant'

      tenant_name = ENV['TENANT']
      redis_key   = "ekylibre:admin:dump:#{tenant_name}"
      archive_dir = Rails.root.join('tmp', 'archives')

      set_status = lambda do |status, message|
        Sidekiq.redis { |r| r.hmset(redis_key, 'status', status, 'message', message.to_s) }
      end

      set_status.call('running', "Création de l'archive '#{tenant_name}' en cours...")

      begin
        FileUtils.mkdir_p(archive_dir)
        Ekylibre::Tenant.dump(tenant_name, path: archive_dir, verbose: false)
        set_status.call('done', "Archive '#{tenant_name}.zip' prête au téléchargement.")
      rescue => e
        set_status.call('error', "Erreur : #{e.message}")
        raise
      end
    end
  end
end
