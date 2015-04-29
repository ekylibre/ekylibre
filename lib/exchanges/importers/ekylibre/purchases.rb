# Create or updates purchases
Exchanges.add_importer :ekylibre_purchases do |file, w|

  rows = CSV.read(file, headers: true)
  w.count = rows.size
  purchase_ids = []
  now = Time.now

  vinfos = 9 - 1

  rows.each_with_index do |row, index|
    line_index = index + 2

    r = {
      invoiced_at:        (row[0].blank? ? nil : Date.civil(*row[0].split("-").map(&:to_i))),
      supplier_full_name: (row[1].blank? ? nil : row[1]),
      reference_number:   (row[2].blank? ? nil : row[2].upcase),
      variant_code:       (row[3].blank? ? nil : row[3]),
      annotation:         (row[4].blank? ? nil : row[4]),
      quantity:           (row[5].blank? ? nil : row[5].gsub(",", ".").to_d),
      unit_pretax_amount: (row[6].blank? ? nil : row[6].gsub(",", ".").to_d),
      vat_percentage:     (row[7].blank? ? nil : row[7].gsub(",", ".").to_d),
      depreciate:         %w(1 t true yes ok).include?(row[8].to_s.strip.downcase),
      # Variant definition
      variant: {
        variety:                 row[vinfos + 1],
        product_account:         row[vinfos + 2],
        charge_account:          row[vinfos + 3],
        financial_asset_account: row[vinfos + 4],
        financial_asset_allocation_account: row[vinfos + 5],
        financial_asset_expenses_account:   row[vinfos + 6]
      },

      # Extra infos
      document_reference_number: "#{row[0]}_#{row[1]}_#{row[2]}".gsub(" ", "-"),
      description: now.l
    }.to_struct

    # Find or import a variant
    unless r.variant_code
      raise "Variant identifiant must be given at line #{line_index}"
    end
    unless variant = ProductNatureVariant.find_by(number: r.variant_code)
      if Nomen::ProductNatureVariants.find(r.variant_code)
        variant = ProductNatureVariant.import_from_nomenclature(r.variant_code)
      else
        if r.variant[:financial_asset_account]
          suffix = r.variant[:financial_asset_account][1..-1]
          r.variant[:financial_asset_allocation_account] ||= "28#{suffix}"
          r.variant[:financial_asset_expenses_account]   ||= "68#{suffix}"
          r.variant[:financial_asset_depreciation_method] ||= :simplified_linear
          r.variant[:financial_asset_depreciation_percentage] ||= 15
        end
        %w(product charge financial_asset financial_asset_allocation financial_asset_expenses).each do |type|
          key = "#{type}_account".to_sym
          account_infos = r.variant[key].to_s.split(":")
          account_number = account_infos.shift
          account_name = account_infos.shift
          unless account_number.blank?
            unless account = Account.find_by(number: account_number.strip)
              account = Account.create!(name: account_name || account_number, number: account_number)
            end
            r.variant[key] = account
          end
        end
        attrs = r.variant.select{|k,v| !v.blank? and k != :variety}
        attrs[:name] = r.variant_code
        attrs[:saleable] = true if attrs[:product_account]
        attrs[:purchasable] = true if attrs[:charge_account]
        attrs[:depreciable] = true if attrs[:financial_asset_account]
        unless category = ProductNatureCategory.find_by(attrs)
          category = ProductNatureCategory.create!(attrs.merge(active: true, pictogram: :undefined))
        end
        attrs[:variety]  = r.variant[:variety] || :product
        unless nature = category.natures.first
          nature = category.natures.create!(name: attrs[:name], variety: attrs[:variety])
        end
        unless variant = nature.variants.first
          variant = nature.variants.create!(name: attrs[:name], variety: attrs[:variety], unit_name: "Unit")
        end
      end
    end
    unless variant
      raise "Unknown variant at line #{line_index}"
    end

    # Find or create a purchase
    # if supplier and r.invoiced_at and r.reference_number
    # see if purchase exist anyway
    unless purchase = Purchase.find_by(reference_number: r.reference_number)
      # Find supplier
      unless supplier = Entity.where("full_name ILIKE ?", r.supplier_full_name).first
        raise "Cannot find supplier #{r.supplier_full_name} at line #{line_index}"
      end
      unless r.invoiced_at
        raise "Missing invoice date at line #{line_index}"
      end
      purchase = Purchase.create!(planned_at: r.invoiced_at,
                                  invoiced_at: r.invoiced_at,
                                  reference_number: r.reference_number,
                                  supplier: supplier,
                                  nature: PurchaseNature.actives.first,
                                  description: r.description
                                 )
      purchase_ids << purchase.id
    end

    # Find or create a tax
    # TODO search country before for good tax request (country and amount)
    # country via supplier if information exist
    unless r.vat_percentage
      raise "Missing VAT at line #{line_index}"
    end
    item = Nomen::Taxes.find_by(country: purchase.supplier.country.to_sym, amount: r.vat_percentage)
    tax = Tax.import_from_nomenclature(item.name)

    # find or create a purchase line
    unless purchase_item = purchase.items.find_by(pretax_amount: r.pretax_amount, variant_id: variant.id, tax_id: tax.id)
      unless r.quantity
        raise "Missing quantity at line #{line_index}"
      end
      purchase.items.create!(quantity: r.quantity, tax: tax, unit_pretax_amount: r.unit_pretax_amount, variant: variant, fixed: r.depreciate)
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
