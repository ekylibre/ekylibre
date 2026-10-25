namespace :admin do
  namespace :restore do
    desc 'Restore a tenant archive (called from admin UI, tracks status in Redis)'
    task run: :environment do
      require 'ekylibre/tenant'

      redis_key    = 'ekylibre:admin:restore'
      archive_path = Pathname.new(ENV['ARCHIVE'])
      tenant_name  = ENV['TENANT']

      set_status = lambda do |status, message|
        Sidekiq.redis { |r| r.hmset(redis_key, 'status', status, 'message', message.to_s) }
      end

      set_status.call('running', "Restauration de '#{tenant_name}' en cours...")

      begin
        Ekylibre::Tenant.restore(archive_path, tenant: tenant_name, verbose: false, force: true)
        set_status.call('done', "Le tenant '#{tenant_name}' a été restauré avec succès.")
      rescue => e
        Ekylibre::Tenant.drop(tenant_name) if Ekylibre::Tenant.exist?(tenant_name)
        set_status.call('error', "Erreur : #{e.message}")
        raise
      end
    end
  end
end
