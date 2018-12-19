# This object allow printing the general ledger
class BalanceSheetPrinter
  include PdfPrinter

  def initialize(options)
    @document_nature = Nomen::DocumentNature.find(options[:document_nature])
    @key             = options[:key]
    @template_path   = find_open_document_template(options[:document_nature])
    @params          = options[:params]
    @financial_year  = options[:financial_year]
  end

  def compute_dataset
    dataset = []

    dataset.compact
  end

  def run_pdf
    dataset = compute_dataset

    report = generate_document(@document_nature, @key, @template_path) do |r|

      # build header
      e = Entity.of_company
      company_name = e.full_name
      company_address = e.default_mail_address&.coordinate

      # build filters
      data_filters = []

      # build started and stopped
      tax_declaration = TaxDeclaration.find(@params[:id])
      started_on = tax_declaration.started_on
      stopped_on = tax_declaration.stopped_on

      r.add_field 'COMPANY_ADDRESS', company_address
      r.add_field 'DOCUMENT_NAME', I18n.translate("labels.#{tax_declaration.state}_vat_declaration")
      r.add_field 'FILE_NAME', @key
      r.add_field 'PERIOD', I18n.translate('labels.from_to_date', from: started_on.l, to: stopped_on.l)
      r.add_field 'DATE', Date.today.l
      r.add_field 'STARTED_ON', started_on.to_date.l
      r.add_field 'STOPPED_ON', stopped_on.to_date.l
      r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
      r.add_field 'DATA_FILTERS', data_filters * ' | '
      r.add_field 'VAT_BALANCE', dataset[-2]
      r.add_field 'VAT_BALANCE_AMOUNT', dataset[-1]

    end
    report.file.path
  end

end
