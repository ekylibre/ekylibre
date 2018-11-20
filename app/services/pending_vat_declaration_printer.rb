
# This object allow printing the general ledger
class PendingVatDeclarationPrinter
  include PdfPrinter

    def initialize(options)
      @document_nature = options[:document_nature]
      @key             = options[:key]
      @template_path   = options[:template_path]
      @params          = options[:params]
    end

    def compute_dataset

      vat_dataset = []

      if @params[:id].to_i > 0
        taxe_declaration = TaxDeclaration.find(@params[:id])
        taxes = Tax.where(id: taxe_declaration.items.pluck(:tax_id)).reorder(amount: :desc)
      end

      columns = [:collected, :intracommunity_payable, :deductible, :fixed_asset_deductible]
      account_transcode = { collected: :collect_account_id, deductible: :deduction_account_id, fixed_asset_deductible: :fixed_asset_deduction_account_id, intracommunity_payable: :intracommunity_payable_account_id }

      columns.each do |c|
        #section 1
        cat = HashWithIndifferentAccess.new
        cat[:name] = TaxDeclarationItem.human_attribute_name(c.to_sym)
        cat[:items] = []
        taxes.each do |t|
          #section 2
          cat_taxe = HashWithIndifferentAccess.new
          cat_taxe[:name] = t.name
          cat_taxe[:items] = []
          taxe_total_tax = 0.0
          taxe_total_pretax = 0.0
          taxe_declaration.items.where(tax_id: t.id).includes(parts: { journal_entry_item: :entry }).each do |i|
            #table 1
            i.parts.each do |p|
              jei = p.journal_entry_item
              e = jei.entry
              item = HashWithIndifferentAccess.new
              item[:entry_number] = e.number
              item[:entry_printed_on] = e.printed_on.l
              item[:item_account] = jei.vat_item_to_product_account
              item[:entry_item_name] = jei.name
              item[:tax_amount] = p.tax_amount.to_f
              item[:pretax_amount] = p.pretax_amount.to_f
              item[:amount] = (p.pretax_amount.to_f + p.tax_amount.to_f).round(2)
              cat_taxe[:items] << item
            end

            taxe_total_tax += i.send("#{c}_tax_amount")
            taxe_total_pretax += i.send("#{c}_pretax_amount")
          end
          cat_taxe[:pretax_amount] = taxe_total_pretax
          cat_taxe[:tax_amount] = taxe_total_tax
          cat[:items] << cat_taxe
        end
        cat[:pretax_amount] = taxe_declaration.items.sum("#{c}_pretax_amount")
        cat[:tax_amount] = taxe_declaration.items.sum("#{c}_tax_amount")
        vat_dataset << cat
      end
      to_pay = taxe_declaration.items.sum(:balance_tax_amount)
      if to_pay >= 0.0
        vat_label  = :to_pay.tl
        vat_balance = to_pay
      else
        vat_label = :to_reclaim.tl
        vat_balance = -to_pay
      end
      vat_dataset << vat_label
      vat_dataset << vat_balance
      vat_dataset.compact
    end

    def run_pdf
      report = generate_document(@document_nature, @key, @template_path) do |r|

        # build header
        e = Entity.of_company
        company_name = e.full_name
        company_address = e.default_mail_address&.coordinate

        # build filters
        data_filters = []

        # build started and stopped
        if @params[:id].to_i > 0
          taxe_declaration = TaxDeclaration.find(@params[:id])
          started_on = taxe_declaration.started_on
          stopped_on = taxe_declaration.stopped_on
        end

        r.add_field 'COMPANY_ADDRESS', company_address
        r.add_field 'DOCUMENT_NAME', @document_nature.human_name
        r.add_field 'FILE_NAME', @key
        r.add_field 'PERIOD', I18n.translate('labels.from_to_date', from: started_on.l, to: stopped_on.l)
        r.add_field 'DATE', Date.today.l
        r.add_field 'STARTED_ON', started_on.to_date.l
        r.add_field 'STOPPED_ON', stopped_on.to_date.l
        r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
        r.add_field 'DATA_FILTERS', data_filters * ' | '

        #TODO

      end
      report.file.path
    end

end
