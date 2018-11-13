
# This object allow printing the general ledger
class VatPrinter
  include PdfPrinter

    def initialize(options)
      @dataset     = options[:dataset]
      @document_nature = options[:document_nature]
      @key             = options[:key]
      @template_path   = options[:template_path]
      @params          = options[:params]
    end

    def run
      report = generate_document(@document_nature, @key, @template_path) do |r|

        # build header
        e = Entity.of_company
        company_name = e.full_name
        company_address = e.default_mail_address&.coordinate

        # build filters
        data_filters = []

        # build started and stopped
        started_on = @params[:period].split('_').first if @params[:period]
        stopped_on = @params[:period].split('_').last if @params[:period]

        r.add_field 'COMPANY_ADDRESS', company_address
        r.add_field 'DOCUMENT_NAME', @document_nature.human_name
        r.add_field 'FILE_NAME', @key
        r.add_field 'PERIOD', @period == 'all' ? :on_all_exercises.tl : I18n.translate('labels.from_to_date', from: Date.parse(@period.split('_').first).l, to: Date.parse(@period.split('_').last).l)
        r.add_field 'DATE', Date.today.l
        r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
        r.add_field 'DATA_FILTERS', data_filters * ' | '

        r.add_table('Tableau1', balances, header: false) do |t|

        end
      end
      report.file.path
    end
end
