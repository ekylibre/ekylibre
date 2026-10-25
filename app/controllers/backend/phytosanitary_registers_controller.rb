module Backend
  class PhytosanitaryRegistersController < Backend::BaseController
    DOCUMENT_NATURE = 'phytosanitary_register'

    SUPPORTED_FORMATS = {
      'xml' => { mime: 'application/xml', exporter: ::Phytosanitary::Register::Exporters::XmlExporter },
      'json' => { mime: 'application/json', exporter: ::Phytosanitary::Register::Exporters::JsonExporter },
      'csv' => { mime: 'text/csv', exporter: ::Phytosanitary::Register::Exporters::CsvExporter }
    }.freeze

    def index
      @documents = Document.where(nature: DOCUMENT_NATURE).order(created_at: :desc)
      @campaigns = Campaign.order(harvest_year: :desc)
    end

    def show
      @document = Document.where(nature: DOCUMENT_NATURE).find(params[:id])
      redirect_to backend_document_path(@document)
    end

    def preview
      @campaign = Campaign.find_by(id: params[:campaign_id])
      @payload = ::Phytosanitary::Register::Builder.call(campaign: @campaign)
      @validation = ::Phytosanitary::Register::IntegrityValidator.call(@payload)
    end

    def create
      campaign = Campaign.find_by(id: params[:campaign_id])
      requested_format = params[:export_format].to_s.downcase
      format_config = SUPPORTED_FORMATS[requested_format]

      unless format_config
        notify_error(:phytosanitary_register_unknown_format, format: requested_format)
        redirect_to action: :index
        return
      end

      payload = ::Phytosanitary::Register::Builder.call(campaign: campaign)
      validation = ::Phytosanitary::Register::IntegrityValidator.call(payload)

      unless validation.ok? || params[:force] == 'true'
        flash[:error] = :phytosanitary_register_incomplete.tl(count: validation.total_errors)
        redirect_to action: :preview, campaign_id: campaign&.id
        return
      end

      content = format_config[:exporter].call(payload)
      filename = build_filename(payload, campaign, requested_format)
      file_path = Ekylibre::Tenant.private_directory.join('tmp', filename)
      FileUtils.mkdir_p(file_path.dirname)
      File.write(file_path, content)

      document = Document.create!(
        nature: DOCUMENT_NATURE,
        key: "#{Time.now.to_i}-#{filename}",
        name: filename,
        file: File.open(file_path, 'rb')
      )

      notify_success(:phytosanitary_register_generated, count: payload.size)
      redirect_to backend_document_path(document)
    end

    private

      def build_filename(payload, campaign, format)
        siret = payload.holder_siret.presence || 'farm'
        period = campaign&.name.presence || Time.zone.today.strftime('%Y')
        "registre_phyto_#{siret}_#{period}_#{Time.zone.today.strftime('%Y%m%d')}.#{format}"
      end
  end
end
