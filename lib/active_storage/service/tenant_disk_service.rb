# frozen_string_literal: true

require 'active_storage/service/disk_service'

module ActiveStorage
  # Disk service whose root follows the current tenant.
  #
  # Active Storage resolves its service once at boot, but Ekylibre is
  # multi-tenant: each tenant's files live under its own private directory, and
  # `Ekylibre::Tenant.dump` archives exactly that directory. Writing blobs to a
  # single shared root would silently drop them from every tenant archive — and
  # from `Ekylibre::Tenant.restore` with them.
  #
  # So the root is computed per call rather than frozen at boot. Blob keys are
  # random, so this is about keeping a tenant's files inside its own directory,
  # not about avoiding collisions.
  #
  # Configured in config/storage.yml with `service: TenantDisk`. The `root:`
  # option is only the fallback used when no tenant is current (rake tasks, the
  # admin namespace, the public schema).
  class Service
    class TenantDiskService < DiskService
      STORAGE_DIRNAME = 'storage'

      # @return [String] absolute path of the storage root for the current tenant
      def root
        tenant_root || super
      end

      private

        # @return [String, nil] nil when no tenant is currently selected
        def tenant_root
          return nil unless defined?(::Ekylibre::Tenant)

          tenant = ::Ekylibre::Tenant.current
          return nil if tenant.blank?

          ::Ekylibre::Tenant.private_directory(tenant).join(STORAGE_DIRNAME).to_s
        rescue StandardError
          # No tenant selected, or Apartment not ready: fall back to the
          # configured root rather than blowing up on an unrelated code path.
          nil
        end
    end
  end
end
