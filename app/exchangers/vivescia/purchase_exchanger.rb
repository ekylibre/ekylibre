module Vivescia
  # Exchanger to import COFTW.isa files from IsaCompta software
  class PurchaseExchanger < ActiveExchanger::Base
    def check
      SVF::EdiFactInvoic.parse(file)
    rescue SVF::InvalidSyntax
      return false
    end

    def import
      # path = "/home/djoulin/projects/integration-cer-cneidf/db/first_runs/gaec-hureau/vivescia/appros.edi"
      # file = File.open(path)

      # please refer to lib/svf/norms/edi/fact_invoic.yml

      units_transcode = { 'KGM' => :kilogram,
                          'DTN' => :quintal,
                          'KK' => :quintal,
                          'GRM' => :gram,
                          'TNE' => :ton,
                          'EA' => :unity,
                          'NAR' => :unity,
                          'DOS' => :unity,
                          'PCE' => :unity,
                          'MTR' => :meter,
                          'KMT' => :kilometer,
                          'LTR' => :liter,
                          'MTQ' => :cubic_meter }

      # Load hash to transcode EDI items categories to variant
      here = Pathname.new(__FILE__).dirname
      inputs_transcode = {}.with_indifferent_access
      CSV.foreach(here.join('inputs.csv'), headers: true) do |row|
        inputs_transcode[row[0]] = row[1].to_sym
      end

      # use edi_purchase_item.work_number on LIN segment
      catalog_transcode = {}.with_indifferent_access
      CSV.foreach(here.join('catalog.csv'), headers: true) do |row|
        catalog_transcode[row[1]] = { name: row[4], unit: units_transcode[row[5]], account_number: row[6], account_name: row[7]}
      end

      begin
        edifact = SVF::EdiFactInvoic.parse(file)
      rescue SVF::InvalidSyntax
        raise ActiveExchanger::NotWellFormedFileError
      end

      w.count = edifact.purchases.count
      purchase_ids = []

      sender_name = 'Vivescia'
      sender = Entity.find_by(last_name: sender_name) ||
               Entity.where('last_name ILIKE ?', sender_name).first ||
               Entity.create!(nature: :organization,
                              last_name: sender_name,
                              supplier: true)

      edifact.purchases.each do |edi_purchase|
        purchase = PurchaseInvoice.create!(
          planned_at: Time.parse(edi_purchase.header.purchase_printed_on),
          invoiced_at: Time.parse(edi_purchase.header.purchase_printed_on),
          reference_number: edi_purchase.header.purchase_number,
          supplier: sender,
          nature: PurchaseNature.actives.first,
          description: edi_purchase.header.purchase_title
        )

        purchase_ids << purchase.id

        edi_purchase.items.each do |edi_purchase_item|

          # transcode detail number in EDI into variant nomen
          pivot = catalog_transcode[edi_purchase_item.work_number]

          # try to find the correct variant from id of provider
          product_nature_variant = ProductNatureVariant.where('providers ->> ? = ?', sender.id, edi_purchase_item.work_number).first if edi_purchase_item.work_number.present?
          # try to find the correct variant from name
          product_nature_variant ||= ProductNatureVariant.where('name ILIKE ?', edi_purchase_item.detail.description).first
          # create the variant
          unless product_nature_variant
            # find the correct category of product bases on pivot
            account_number = pivot[:account_number].sub!(/0+$/, '')
            account = Account.find_or_create_by_number(account_number) do |a|
              a.name = pivot[:account_name]
            end
            # find category by charge or product account
            pnc = ProductNatureCategory.where(charge_account_id: account.id).first
            pnc ||= ProductNatureCategory.where(product_account_id: account.id).first
            unless pnc
              puts 'No categories availables'
              next
            end
            product_nature_variant = ProductNatureVariant.where(category_id: pnc.id).first
            product_nature_variant.providers = { sender.id => edi_purchase_item.work_number } if edi_purchase_item.work_number.present?
            product_nature_variant.name = pivot[:name]
            product_nature_variant.unit_name = Nomen::Unit[pivot[:unit]].human_name
            product_nature_variant.save!
          end

          item = Nomen::Tax.find_by(country: purchase.supplier.country.to_sym, amount: edi_purchase_item.tax.rate.to_f)
          tax = Tax.import_from_nomenclature(item.name)

          purchase.items.create!(quantity: edi_purchase_item.quantity,
                                 tax: tax,
                                 unit_pretax_amount: edi_purchase_item.price_unit,
                                 variant: product_nature_variant)
        end

        w.check_point
      end

      # Restart counting
      added_purchases = PurchaseInvoice.where(id: purchase_ids)
      w.reset! added_purchases.count, :yellow

      # change status of all new added purchases
      added_purchases.each do |purchase|
        purchase.propose if purchase.draft?
        purchase.confirm
        purchase.invoice(purchase.invoiced_at)
        w.check_point
      end
    end
  end
end
