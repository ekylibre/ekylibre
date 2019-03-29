require 'test_helper'

module Ekylibre
  class TenantTest < ActiveSupport::TestCase
    def test_tenant_creation
      Ekylibre::Tenant.create('foobar')
      assert Ekylibre::Tenant.exist?('foobar')
      Ekylibre::Tenant.switch!('foobar')
      assert_equal 'foobar', Ekylibre::Tenant.current
      Ekylibre::Tenant.create('foobarbaz')
      Ekylibre::Tenant.switch('foobarbaz') do
        assert_equal 'foobarbaz', Ekylibre::Tenant.current
      end
      assert_equal 'foobar', Ekylibre::Tenant.current
      Ekylibre::Tenant.drop('foobarbaz')
      Ekylibre::Tenant.drop('foobar')
      Ekylibre::Tenant.switch!('test')
      assert !Ekylibre::Tenant.exist?('foobar')
      assert !Ekylibre::Tenant.exist?('foobarbaz')
    end

    def test_backup_v3
      # We use public schema because outside dump is not possible outside
      # of a transaction. So we backup an existing schema
      name = 'public'

      # Dump
      Ekylibre::Tenant.send(:dump_v3, name)
      file = Rails.root.join('tmp', 'archives', "#{name}.zip")
      path = Rails.root.join('tmp', "test-#{name}-unzipped")
      FileUtils.rm_rf path.to_s
      FileUtils.mkdir_p path.to_s
      # Open zip and check manifest.yml
      Zip::File.open(file.to_s) do |zile|
        zile.each do |entry|
          entry.extract(path.join(entry.name))
        end
      end
      infos = YAML.load_file(path.join('manifest.yml'))
      assert_equal name, infos['tenant']

      # # Restore
      # Ekylibre::Tenant.send(:restore, file, tenant: 'foobarbaz')
      # assert Ekylibre::Tenant.exist?('foobarbaz')
    end
  end
end
