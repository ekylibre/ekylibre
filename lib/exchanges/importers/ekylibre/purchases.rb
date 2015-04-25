# Create or updates purchases
Exchanges.add_importer :ekylibre_purchases do |file, w|

  rows = CSV.read(file, headers: true).delete_if{|r| r[0].blank?}
  w.count = rows.size
  purchase_ids = []
  now = Time.now

  rows.each do |row|
    # FIXME So ugly, we have to use many columns for the "document_reference_number", it's "unbitable"
    very_long_reference = (row[0].blank? ? nil : row[0].to_s)
    arr = []
    # get information from document_reference_number
    # first part = purchase_invoiced_at
    # second part = supplier_full_name (replace - by space)
    # third part = purchase_reference_number
    if very_long_reference
      arr = very_long_reference.strip.downcase.split('_')
      # purchase_invoiced_at = arr[0].to_datetime
      # supplier_full_name = arr[1].to_s.gsub("-", " ")
      # purchase_reference_number = arr[2].to_s.upcase
      # # set description
      # description = very_long_reference + " - "
      # description << Time.now.l.to_s
    end


    r = {
      document_reference_number: very_long_reference,
      invoiced_at: (very_long_reference ? arr[0].to_datetime : nil),
      supplier_full_name: (very_long_reference ? arr[1].to_s.gsub("-", " ") : nil),
      reference_number: arr[2].to_s.upcase,
      description: very_long_reference + " - " + now.l,
      variant_code: (row[1].blank? ? nil : row[1].to_sym),
      quantity: (row[2].blank? ? nil : row[2].gsub(",", ".").to_d),
      unit_pretax_amount: (row[3].blank? ? nil : row[3].gsub(",", ".").to_d),
      vat_percentage: (row[4].blank? ? nil : row[4].gsub(",", ".").to_d),
      valid: (row[5].blank? ? false : true),
      depreciate: (row[6].blank? ? false : true)
    }.to_struct


    # find an supplier
    if r.supplier_full_name
      supplier = Entity.where("full_name ILIKE ?", r.supplier_full_name).first
    end

    # Find or import a variant
    if r.variant_code
      unless variant = ProductNatureVariant.find_by(number: r.variant_code)
        if Nomen::ProductNatureVariants.find(r.variant_code)
          variant = ProductNatureVariant.import_from_nomenclature(r.variant_code)
        end
      end
    end

    # find or create a purchase
    if supplier and r.invoiced_at and r.reference_number
      # see if purchase exist anyway
      unless purchase = Purchase.find_by(reference_number: r.reference_number)
        purchase = Purchase.create!(planned_at: r.invoiced_at,
                                    invoiced_at: r.invoiced_at,
                                    reference_number: r.reference_number,
                                    supplier: supplier,
                                    nature: PurchaseNature.actives.first,
                                    description: r.description
                                   )
        purchase_ids << purchase.id
      end
    end

    # find or create a tax
    # TODO search country before for good tax request (country and amount)
    # country via supplier if information exist
    purchase_item_tax = nil
    if r.vat_percentage and supplier and supplier.country
      if item = Nomen::Taxes.find_by(country: supplier.country.to_sym, amount: r.vat_percentage)
        purchase_item_tax = Tax.import_from_nomenclature(item.name)
      end
    end

    # find or create a purchase line
    if purchase and variant and r.unit_pretax_amount and r.quantity and purchase_item_tax
      unless purchase_item = PurchaseItem.find_by(purchase_id: purchase.id, pretax_amount: r.pretax_amount, variant_id: variant.id)
        # TODO add depreciable purchase
        purchase.items.create!(quantity: r.quantity, tax: purchase_item_tax, unit_pretax_amount: r.unit_pretax_amount, variant: variant, fixed: r.depreciate)
      end
    end

    w.check_point
  end

  # Restart counting
  added_purchases = Purchase.where(id: purchase_ids)
  w.reset! added_purchases.count, :yellow

  # change status of all new added purchases
  added_purchases.each do |purchase|
    purchase.propose if purchase.draft?
    purchase.confirm
    purchase.invoice(purchase.invoiced_at)
    w.check_point
  end

end
