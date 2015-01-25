# Create or updates purchases
Exchanges.add_importer :ekylibre_sales do |file, w|

  rows = CSV.read(file, headers: true).delete_if{|r| r[0].blank?}
  w.count = rows.size

  rows.each do |row|
    r = {
      document_reference_number: (row[0].blank? ? nil : row[0].to_s),
      variant_nomen: (row[1].blank? ? nil : row[1].to_sym),
      quantity: (row[2].blank? ? nil : row[2].gsub(",", ".").to_d),
      unit_pretax_amount: (row[3].blank? ? nil : row[3].gsub(",", ".").to_d),
      vat_rate: (row[4].blank? ? nil : row[4].gsub(",", ".").to_d),
      description: (row[5].blank? ? '' : row[5].to_s)
    }.to_struct

    # get information from document_reference_number
    # first part = sale_invoiced_at
    # second part = entity_full_name (replace - by space)
    # third part = sale_reference_number
    if r.document_reference_number
      arr = r.document_reference_number.strip.downcase.split('_')
      sale_invoiced_at = arr[0].to_datetime
      entity_full_name = arr[1].to_s.gsub("-", " ")
      sale_reference_number = arr[2].to_s.upcase
    end

    country =  Entity.of_company.country || Preference[:country]

    # find an entity
    if entity_full_name
      entity = Entity.where("full_name ILIKE ?", entity_full_name).first
    end

    # find or import a variant
    if r.variant_nomen
     variant = ProductNatureVariant.import_from_nomenclature(r.variant_nomen)
    end

    # find or create a purchase
    if entity and sale_invoiced_at and sale_reference_number
      # see if purchase exist anyway
      unless sale = Sale.where(reference_number: sale_reference_number).first
        sale = Sale.create!( invoiced_at: sale_invoiced_at,
                             reference_number: sale_reference_number,
                             client_id: entity.id,
                             nature: SaleNature.actives.first,
                             description: r.description
                             )
      end
    end

    # find or create a tax
    # TODO search country before for good tax request (country and amount)
    # country via entity if information exist
    if r.vat_rate and country
      item = Nomen::Taxes.where(country: country.to_sym, amount: r.vat_rate).first
      if item
        unless sale_item_tax = Tax.where(reference_name: item.name).first
          sale_item_tax = Tax.import_from_nomenclature(item.name)
        end
      end
    end

    # find or create a purchase line
    if sale and variant and r.unit_pretax_amount and r.quantity and sale_item_tax
      unless sale_item = SaleItem.where(sale_id: sale.id, pretax_amount: r.pretax_amount, variant_id: variant.id).first
        sale.items.create!(quantity: r.quantity, tax: sale_item_tax, unit_pretax_amount: r.unit_pretax_amount, variant: variant)
      end
    end

    w.check_point
  end
end
