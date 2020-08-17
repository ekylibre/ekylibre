namespace :tva_declaration do
  desc "Generate tax declaration for one month"
  # use it with command : rake tva_declaration:tax_declaration
  task tax_declaration: :environment do |t, args|
    set_parameters(args, false)
    puts 'start to generate tax_declaration it could take a while...'.green
    l = []
    fy = FinancialYear.on(@started_on)
    td = TaxDeclaration.create!(financial_year: fy, started_on: @started_on, stopped_on: @started_on.end_of_month)
    path = "private/integration/tmp/taxdecl#{td.id}.csv"
    CSV.open(path, 'w') do |csv|
      csv_generation(td, csv)
    end
    td.attachments.create!(document: Document.create!(file: File.open(path)))
    puts 'Tax declaration is generated'.green
  end

  desc "Generate tax declaration file"
  task tax_declaration_file: :environment do |t, args|
    set_parameters(args)
    create_tax_declaration_file
  end

  private

    def csv_generation(td, csv)
      td.items.includes(parts: { journal_entry_item: :entry }).each do |i|
        i.parts.each do |p|
          jei = p.journal_entry_item
          e = jei.entry
          csv << [e.number, e.printed_on.l, I18n.l(Date::MONTHNAMES[e.printed_on.month]), jei.account.number, jei.account.name, jei.name, jei.debit.to_f, jei.credit.to_f, p.tax_amount.to_f, p.pretax_amount.to_f, jei.tax.name, jei.vat_item_to_product_account]
        end
      end
    end

    def create_tax_declaration_file
      puts 'Start to generate_file'.green
      taxe_declarations = TaxDeclaration.where('started_on >= ? AND stopped_on <= ?', @started_on, @stopped_on)
      path = "private/integration/tmp/year-tax-declarations#{@started_on}.csv"
      CSV.open(path, 'w') do |csv|
        taxe_declarations.each do |td|
          csv_generation(td, csv)
        end
      end
      puts "File is generated => #{path}".green
    end

    def set_parameters(args, end_date = true)
      until @tenant.present?
        puts 'Enter tenant name :'.blue
        @tenant = STDIN.gets.chomp
      end
      puts "#{Ekylibre::Tenant.switch!(@tenant)}".yellow

      until @started_on.present?
        puts 'Enter date of start (dd/mm/yyyy):'.blue
        @started_on = STDIN.gets.chomp.to_date
      end
      puts "#{@started_on}".yellow

      if end_date
        puts 'Enter date of end (empty if end of month) (dd/mm/yyyy):'.blue
        @stopped_on = STDIN.gets.chomp&.to_date || @started_on.end_of_month
        puts "#{@stopped_on}".yellow
      end
    end
end
