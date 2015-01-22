# Create or updates purchases
Exchanges.add_importer :ekylibre_purchases do |file, w|

  rows = CSV.read(file, headers: true).delete_if{|r| r[0].blank?}
  w.count = rows.size

  rows.each do |row|
    r = {
      document_reference_number: (row[0].blank? ? nil : row[0].to_s),
      variant_nomen: (row[1].blank? ? nil : row[1].to_sym),
      quantity: (row[2].blank? ? nil : row[2].gsub(",", ".").to_d),
      unit_pretax_amount: (row[3].blank? ? nil : row[3].gsub(",", ".").to_d),
      vat_rate: (row[4].blank? ? nil : row[4].gsub(",", ".").to_d)
    }.to_struct

    # get information from document_reference_number
    # first part = purchase_invoiced_at
    # second part = entity_full_name (replace - by space)
    # third part = purchase_reference_number
    if r.document_reference_number
      arr = r.document_reference_number.strip.downcase.split('_')
      purchase_invoiced_at = arr[0].to_datetime
      entity_full_name = arr[1].to_s.gsub("-", " ")
      purchase_reference_number = arr[2].to_s.upcase
      # set description
      description = r.document_reference_number + " - "
      description << Time.now.l.to_s
    end

    # find an entity
    if entity_full_name
      entity = Entity.where("full_name ILIKE ?", entity_full_name).first
    end

    # find or import a variant
    if r.variant_nomen
     variant = ProductNatureVariant.import_from_nomenclature(r.variant_nomen)
    end

    # find or create a purchase
    if entity and purchase_invoiced_at and purchase_reference_number
      # see if purchase exist anyway
      unless purchase = Purchase.where(reference_number: purchase_reference_number).first
        purchase = Purchase.create!(planned_at: purchase_invoiced_at,
                                    invoiced_at: purchase_invoiced_at,
                                    reference_number: purchase_reference_number,
                                    supplier_id: entity.id,
                                    nature: PurchaseNature.actives.first,
                                    description: description
                                    )
      end
    end

    # find or create a tax
    # TODO search country before for good tax request (country and amount)
    # country via entity if information exist
    if r.vat_rate and entity and entity.country
      item = Nomen::Taxes.where(country: entity.country.to_sym, amount: r.vat_rate).first
      if item
        unless purchase_item_tax = Tax.where(reference_name: item.name).first
          purchase_item_tax = Tax.import_from_nomenclature(item.name)
        end
      end
    end

    # find or create a purchase line
    if purchase and variant and r.unit_pretax_amount and r.quantity and purchase_item_tax
      unless purchase_item = PurchaseItem.where(purchase_id: purchase.id, pretax_amount: r.pretax_amount, variant_id: variant.id).first
        purchase.items.create!(quantity: r.quantity, tax: purchase_item_tax, unit_pretax_amount: r.unit_pretax_amount, variant: variant)
      end
    end

    w.check_point
  end
end
