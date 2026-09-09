require 'test_helper'

class ConfigTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  # Remplace l'ancien test des interpolations Paperclip :tenant / :private.
  # La garantie est la même — les fichiers d'un tenant restent dans le
  # répertoire qu'archive Ekylibre::Tenant.dump — mais elle porte désormais sur
  # ActiveStorage::Service::TenantDiskService.
  test 'active storage root follows the current tenant' do
    tenant = Ekylibre::Tenant.current
    assert_equal 'test', tenant

    service = ActiveStorage::Blob.service
    assert_kind_of ActiveStorage::Service::TenantDiskService, service
    assert_equal Ekylibre::Tenant.private_directory.join('storage').to_s, service.root
  end
end
