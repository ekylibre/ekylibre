# Phytosanitary register tasks
namespace :phyto_register do
  desc 'Archive the phytosanitary register for the given YEAR (default: last year) across all tenants. Optional TENANT=name to scope to one tenant. Optional FORMAT=xml|json|csv (default xml).'
  task enqueue_all: :environment do
    year = (ENV['YEAR'] || ENV['year']).to_i
    year = Time.zone.today.year - 1 if year.zero?
    format = (ENV['FORMAT'] || ENV['format'] || 'xml').to_s.downcase
    tenant_name = ENV['TENANT'] || ENV['tenant']

    Ekylibre::Tenant.load!
    tenants = tenant_name.present? ? [tenant_name] : Ekylibre::Tenant.list
    puts "Enqueuing phytosanitary register archive (year=#{year}, format=#{format}) for #{tenants.size} tenants".yellow

    tenants.each do |tenant|
      begin
        Ekylibre::Tenant.switch(tenant) do
          PhytosanitaryRegisterArchiveJob.perform_later(year: year, format: format)
          puts "[#{tenant}] enqueued".green
        end
      rescue StandardError => e
        warn "[#{tenant}] failed: #{e.message}".red
      end
    end
  end

  desc 'Verify the SHA256 integrity of all archived phytosanitary registers in TENANT (default: all tenants).'
  task verify: :environment do
    require 'digest/sha2'

    tenant_name = ENV['TENANT'] || ENV['tenant']
    Ekylibre::Tenant.load!
    tenants = tenant_name.present? ? [tenant_name] : Ekylibre::Tenant.list

    total = 0
    bad = 0
    missing = 0

    tenants.each do |tenant|
      Ekylibre::Tenant.switch(tenant) do
        Document.where(nature: PhytosanitaryRegisterArchiveJob::DOCUMENT_NATURE).find_each do |doc|
          total += 1
          stored = doc.sha256_fingerprint.to_s
          path = doc.file.path
          if path.nil? || !File.exist?(path)
            missing += 1
            warn "[#{tenant}] #{doc.id} #{doc.name}: file missing on disk".red
            next
          end
          recomputed = Digest::SHA256.hexdigest(File.read(path))
          if stored.blank?
            missing += 1
            warn "[#{tenant}] #{doc.id} #{doc.name}: no stored sha256 (legacy doc)".yellow
          elsif stored != recomputed
            bad += 1
            warn "[#{tenant}] #{doc.id} #{doc.name}: INTEGRITY MISMATCH (stored=#{stored[0, 12]}… recomputed=#{recomputed[0, 12]}…)".red
          else
            puts "[#{tenant}] #{doc.id} #{doc.name}: OK".green
          end
        end
      end
    end

    puts "\nSummary: #{total} documents, #{total - bad - missing} OK, #{bad} mismatched, #{missing} missing/legacy".yellow
    exit(1) if bad.positive?
  end

  desc 'Run the archive synchronously for the current TENANT, useful for backfill and debugging. Requires TENANT=name. Optional YEAR, FORMAT.'
  task run_now: :environment do
    tenant_name = ENV['TENANT'] || ENV['tenant']
    raise 'TENANT env var is required (e.g. TENANT=acme)' if tenant_name.blank?

    year = (ENV['YEAR'] || ENV['year']).to_i
    year = Time.zone.today.year - 1 if year.zero?
    format = (ENV['FORMAT'] || ENV['format'] || 'xml').to_s.downcase

    Ekylibre::Tenant.switch(tenant_name) do
      document = PhytosanitaryRegisterArchiveJob.perform_now(year: year, format: format)
      puts "Archived #{document.name}".green
    end
  end
end
