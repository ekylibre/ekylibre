require 'digest/sha2'

class PhytosanitaryRegisterArchiveJob < ApplicationJob
  queue_as :default

  DOCUMENT_NATURE = 'phytosanitary_register'
  DEFAULT_FORMAT = 'xml'
  # Arrêté du 24/12/2025 requires a 5-year minimum retention. We add a 1-month
  # buffer so reviews on the last day still find the record alive.
  LEGAL_RETENTION = 5.years + 1.month

  FORMAT_TO_EXPORTER = {
    'xml' => { exporter: ::Phytosanitary::Register::Exporters::XmlExporter, mime: 'application/xml' },
    'json' => { exporter: ::Phytosanitary::Register::Exporters::JsonExporter, mime: 'application/json' },
    'csv' => { exporter: ::Phytosanitary::Register::Exporters::CsvExporter, mime: 'text/csv' }
  }.freeze

  # Year defaults to (today.year - 1) for the canonical "archive last year before
  # January 31" workflow. Pass year explicitly for backfill or manual runs.
  # Format defaults to xml (the regulatory format).
  def perform(year: nil, format: DEFAULT_FORMAT)
    year ||= Time.zone.today.year - 1
    format = format.to_s.downcase
    config = FORMAT_TO_EXPORTER.fetch(format) do
      raise ArgumentError, "Unknown format: #{format}"
    end

    campaign = Campaign.find_by(harvest_year: year)
    payload = ::Phytosanitary::Register::Builder.call(
      campaign: campaign,
      from: Time.zone.local(year, 1, 1),
      to: Time.zone.local(year, 12, 31).end_of_day
    )
    content = config[:exporter].call(payload)
    sha256 = Digest::SHA256.hexdigest(content)
    filename = build_filename(payload, year, format)
    file_path = Ekylibre::Tenant.private_directory.join('tmp', filename)
    FileUtils.mkdir_p(file_path.dirname)
    File.write(file_path, content)

    document = Document.create!(
      nature: DOCUMENT_NATURE,
      key: "#{Time.now.to_i}-#{filename}",
      name: filename,
      file: File.open(file_path, 'rb'),
      sha256_fingerprint: sha256,
      legal_retention_until: Time.zone.today + LEGAL_RETENTION,
      mandatory: true
    )
    Rails.logger.info "[phyto register] archived #{document.name} (#{payload.size} entries, sha256=#{sha256[0, 12]}…)"
    document
  end

  private

    def build_filename(payload, year, format)
      siret = payload.holder_siret.presence || 'farm'
      "registre_phyto_#{siret}_#{year}.#{format}"
    end
end
