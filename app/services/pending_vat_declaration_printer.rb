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

    tax_declaration = TaxDeclaration.find(@params[:id])
    taxes = Tax.where(id: tax_declaration.items.pluck(:tax_id)).reorder(amount: :desc)

    columns = [:collected, :intracommunity_payable, :deductible, :fixed_asset_deductible]
    account_transcode = { collected: :collect_account_id, deductible: :deduction_account_id, fixed_asset_deductible: :fixed_asset_deduction_account_id, intracommunity_payable: :intracommunity_payable_account_id }

    columns.each do |c|
      #section 1
      cat = HashWithIndifferentAccess.new
      cat[:name] = TaxDeclarationItem.human_attribute_name(c)
      cat[:items] = []
      taxes.each do |t|
        #section 2
        cat_tax = HashWithIndifferentAccess.new
        cat_tax[:name] = t.name
        cat_tax[:parts] = []
        tax_total_tax = 0.0
        tax_total_pretax = 0.0
        tax_declaration.items.where(tax_id: t.id).includes(parts: { journal_entry_item: :entry }).each do |i|
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
            cat_tax[:parts] << item
          end

          tax_total_tax += i.send("#{c}_tax_amount")
          tax_total_pretax += i.send("#{c}_pretax_amount")
        end
        cat_tax[:pretax_amount] = tax_total_pretax
        cat_tax[:tax_amount] = tax_total_tax
        cat[:items] << cat_tax
      end
      cat[:pretax_amount] = tax_declaration.items.sum("#{c}_pretax_amount")
      cat[:tax_amount] = tax_declaration.items.sum("#{c}_tax_amount")
      vat_dataset << cat
    end
    to_pay = tax_declaration.items.sum(:balance_tax_amount)
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

      r.add_section('Section1', dataset[0...-2]) do |first_section|
        first_section.add_field(:vat_header) { |item| item[:name] }
        first_section.add_field(:general_pretax_amount) { |item| item[:pretax_amount] }
        first_section.add_field(:general_tax_amount) { |item| item[:tax_amount] }

        first_section.add_section('Section2', :items) do |second_section|
          second_section.add_field(:vat_rate) { |item| item[:name] }
          second_section.add_field(:total_pretax_amount) { |item| item[:pretax_amount] }
          second_section.add_field(:total_tax_amount) { |item| item[:tax_amount] }

          second_section.add_table('Table6', :parts, header: false) do |first_table|
            first_table.add_column(:printed_on) { |part| part[:entry_printed_on] }
            first_table.add_column(:label) { |part| part[:entry_item_name] }
            first_table.add_column(:pretax_amount) { |part| part[:pretax_amount] }
            first_table.add_column(:tax_amount) { |part| part[:tax_amount] }
          end
        end
      end
    end
    report.file.path
  end
end
