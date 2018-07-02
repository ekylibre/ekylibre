# coding: utf-8
module FermesLarrere
  class SalesExchanger < ActiveExchanger::Base
    PALLET_QUANTITY_UNIT_NAME = :kilogram
    PALLET_QUANTITY_UNIT_HUMAN_NAME = Nomen::Unit[PALLET_QUANTITY_UNIT_NAME].human_name
    PALLET_QUANTITY_UNIT = 1.0.in(PALLET_QUANTITY_UNIT_NAME) # Old "a"
    CONSIGN_VARIANT_ID = 7074
    CONSIGN_TAX_ID = 21

    def import
      rows = Roo::Excelx.new(file)
      # exclude headers
      w.count = rows.count > 0 ? rows.count - 1 : 0

      return unless rows.count > 1

      previous_sale = nil
      previous_pretax_amount = nil
      previous_amount = nil
      rows.each_row_streaming(offset: 1, pad_cells: true, max_rows: rows.count - 2) do |row|
        r = parse_row(row)

        w.info "LINE REFERENCE : #{r.invoice_origin_reference_number} - #{r.invoice_line_origin_reference_number}".red

        unless r.client_code
          w.check_point
          next
        end

        sale_line_code = r.invoice_origin_reference_number.to_s + '-' + r.invoice_line_origin_reference_number.to_s

        unless Nomen::Country.find(r.client_country_code)
          r.client_country_code = Preference[:country]
        end

        unless Nomen::Country.find(r.client_invoice_country_code)
          r.client_invoice_country_code = Preference[:country]
        end

        # find or initialize an entity
        entity = find_or_create_entity(r)
        raise 'Cannot import sales without client informations' unless entity

        #address = find_or_create_mail_address(entity, r.client_full_name, r.client_address_name, r.client_town_name, r.client_postal_code_name, r.client_country_code)

        #delivery_address = find_or_create_mail_address(entity, r.client_invoice_full_name, r.client_invoice_address_name, r.client_invoice_town_name, r.client_invoice_postal_code_name, r.client_invoice_country_code)

        # Add phone number if given
        #find_or_create_address(entity, :phone, r.client_phone_number)

        # Add fax phone number if given
        #find_or_create_address(entity, :fax, r.client_fax_number)

        # Add email if given
        #if r.client_email && r.client_email.to_s.match(/@/)
        #  find_or_create_address(entity, :email, r.client_email)
        #end

        # find or import a variant
        variant = find_or_create_variant(r)
        raise "What's the fuck? " + [r.variant_gtin, r.variant_name, r.variant_nature_reference_name].to_sentence.red unless variant

        # find or create a sale
        #sale = find_or_create_sale(entity, address, delivery_address, r)
        sale = find_or_create_sale(entity, r)
        unless sale
          next
        end
        if sale.invoice?
          next
        end

        # If we start a new sale, we close the previous one by amount adjusting
        # and invoicing
        if previous_sale && sale != previous_sale
          finish_sale(previous_sale, previous_pretax_amount, previous_amount)
        end

        # find or create a tax
        # TODO: search country before for good tax request (country and amount)
        # country via entity if information exist

        w.info "VAT rate: #{r.origin_vat_id}".red

        # r.client_invoice_country_code

        # find or create a sale line
        find_or_create_sale_item(r, sale, variant, sale_line_code)

        #find_or_create_transporter(r.client_transporter_code)


        previous_sale = sale
        # To fix Euroflow shit computation, we add consign_amount to global
        # pre-tax amount
        previous_pretax_amount = r.invoice_pretax_amount.dup + r.consign_amount
        previous_amount = r.invoice_amount.dup

        w.check_point
      end


      # Finish last sale
      if previous_sale && previous_pretax_amount && previous_amount
        finish_sale(previous_sale, previous_pretax_amount, previous_amount)
      end
    end

    def parse_row(row)
      r = {
        # invoice
        invoice_origin_reference_number:   (row[0].blank? ? nil : row[0].value.to_i.to_s),
        invoice_line_origin_reference_number:   (row[1].blank? ? nil : row[1].value.to_i.to_s),
        created_at:        (row[2].blank? ? nil : Time.zone.parse(row[2].value.to_s)),
        updated_at:        (row[3].blank? ? nil : Time.zone.parse(row[3].value.to_s)),
        # client
        client_code: (row[4].blank? ? nil : row[4].value.to_s),
        client_full_name: (row[5].blank? ? nil : row[5].value.to_s.strip),
        client_address_name: (row[6].blank? ? nil : row[6].value.to_s.strip),
        client_town_name: (row[7].blank? ? nil : row[7].value.to_s.strip),
        client_postal_code_name: (row[8].blank? ? nil : row[8].value.to_s.strip),
        client_country_code: (row[9].blank? ? nil : row[9].value.to_s.downcase),
        client_phone_number: (row[10].blank? ? nil : row[10].value.to_s.strip),
        client_fax_number: (row[11].blank? ? nil : row[11].value.to_s.strip),
        client_email: (row[12].blank? ? nil : row[12].value.to_s.downcase.strip),
        client_vat_number: (row[13].blank? ? nil : row[13].value.to_s.strip.delete(' ')),
        client_siret_number: (row[14].blank? ? nil : row[14].value.to_s.strip.delete(' ')),
        client_account_number: (row[15].blank? ? nil : row[15].value.to_s.strip.delete(' ')),
        # invoice address
        client_invoice_address_code: (row[16].blank? ? nil : row[16].value.to_s),
        client_invoice_full_name: (row[17].blank? ? nil : row[17].value.to_s.strip),
        client_invoice_address_name: (row[18].blank? ? nil : row[18].value.to_s.strip),
        client_invoice_town_name: (row[19].blank? ? nil : row[19].value.to_s.strip),
        client_invoice_postal_code_name: (row[20].blank? ? nil : row[20].value.to_s.strip),
        client_invoice_country_code: (row[21].blank? ? nil : row[21].value.to_s.downcase),
        client_transporter_code: (row[22].blank? ? nil : row[22].value.to_s),
        # variant
        variant_gtin:   (row[23].blank? ? nil : row[23].value.to_s),
        variant_nature_reference_name:   (row[24].blank? ? nil : row[24].value.to_s),
        variant_variety_reference_name:   (row[25].blank? ? nil : row[25].value.to_s),
        variant_derivative_of_reference_name:   (row[26].blank? ? nil : row[26].value.to_s),
        variant_name:   (row[27].blank? ? nil : row[27].value.to_s),
        # line
        quantity: (row[28].blank? || row[28].value.zero? ? nil : row[28].value.to_d),
        unit_pretax_amount: (row[29].blank? ? nil : row[29].value.to_d),
        discount_percentage: (row[30].blank? ? nil : row[30].value.to_d),
        origin_vat_id: row[31].value.to_i,
        transport_fee: (row[32].blank? ? nil : row[32].value.to_d),
        global_discount: (row[33].blank? || row[33].value.zero? ? nil : row[33].value.to_d),
        global_discount_vat_rate: row[34].value.to_s.strip,
        origin_num_piece: (row[35].blank? ? nil : row[35].value.to_s),
        origin_code_lot: (row[36].blank? ? nil : row[36].value.to_s),
        origin_num_pallet: (row[37].blank? ? nil : row[37].value.to_s),
        # quantity_pallet: (row[38].blank? || row[38].value.zero? ? nil : row[38].value.to_d.round(2)),
        # Extra infos
        # 39: sale_item_amount
        invoice_pretax_amount: (row[40].blank? ? nil : row[40].value.to_d),
        invoice_amount: (row[41].blank? ? nil : row[41].value.to_d),
        consign_amount: (row[42].blank? ? nil : row[42].value.to_d),
        # document_reference_number: "#{Date.parse(row[0].to_s)}_#{row[1]}_#{row[2]}".tr(' ', '-')
      }.to_struct
      r.pretax_amount = r.quantity * r.unit_pretax_amount
      r
    end

    def find_or_create_entity(r)
      entity = Entity.where('codes ->> ? = ?', FermesLarrere::EUROFLOW_KEY, r.client_code).first
      unless entity
        entity = Entity.new
        entity.nature = :organization
        entity.codes = { FermesLarrere::EUROFLOW_KEY => r.client_code }
        entity.active = true
        entity.client = true
        w.info 'New entity'.green
      end
      entity.last_name = r.client_full_name
      entity.country = r.client_country_code
      entity.vat_number = r.client_vat_number if r.client_vat_number
      if r.client_siret_number
        if r.client_siret_number =~ /\A\d{9}\z/
          code = r.client_siret_number + '0001'
          entity.siret_number = code + Luhn.control_digit(code).to_s
        elsif r.client_siret_number =~ /\A\d{13}\z/
          entity.siret_number = r.client_siret_number
        end
      end
      w.info "ENTITY SAVE".green
      w.info entity.siret_number.to_s.yellow
      w.info entity.valid?
      entity.save!
      w.info 'OK Entity updated'.green
      entity
    end

    # Find or create a mail with given informations
    #def find_or_create_mail_address(entity, full_name, address_name, town_name, postal_code_name, country_code)
      #return nil unless full_name && address_name && town_name && postal_code_name
      #line_1 = full_name
      #line_4 = address_name
      #line_6 = postal_code_name + ' ' + town_name

      #address = entity.mails.where("mail_line_4 ILIKE ? AND mail_line_6 ILIKE regexp_replace(?, E'\\\s+', ' ', 'g') AND mail_line_1 ILIKE ?", line_4, line_6, line_1).where(mail_country: country_code).first
      #unless address
        #address = entity.mails.create!(
          #mail_line_1: line_1,
          #mail_line_4: line_4,
          #mail_line_6: line_6,
          #mail_country: country_code
        #)
        #w.info 'OK Mail address created'.green
      #end
      #address
    #end

    #def find_or_create_address(entity, canal, coordinate)
      #return nil if coordinate.blank?
      #entity.addresses.find_or_create_by!(canal: canal, coordinate: coordinate)
    #end

    def find_or_create_variant(r)
      # puts '--- find or create variant ---'.yellow
      w.info 'VARIANT--------'.yellow
      # case 1 : variant already exist with GTIN
      if r.variant_gtin.present? && (variant = ProductNatureVariant.find_by(gtin: r.variant_gtin))
      # puts 'Found variant with its GTIN'.green
      # case 3 : variant doesn't exist
      elsif r.variant_name.present? && r.variant_nature_reference_name.present?
        # puts 'Try to find variant with its nature'.yellow
        # transcode to have the right reference name to import variant
        # puts 'Product nature reference: ' + r.variant_nature_reference_name.inspect.green
        if r.variant_nature_reference_name =~ /\A\d+\z/
          nature = ProductNature.find_by!(id: r.variant_nature_reference_name.to_i)
        elsif Nomen::ProductNature.find(r.variant_nature_reference_name.to_sym)
          nature = ProductNature.import_from_nomenclature(r.variant_nature_reference_name.to_sym)
        else
          raise "Cannot find ProductNature with: #{r.variant_nature_reference_name.inspect}"
        end
        variant = nature.variants.find_or_initialize_by(name: r.variant_name)
        w.info 'Found variant with its nature and name'.green
      # case 2 : variant already exist with NAME
      elsif r.variant_name.present? && (variant = ProductNatureVariant.find_by(number: r.variant_name))
        # puts 'Found variant with its number'.green
      elsif r.variant_name.present? && (variant = ProductNatureVariant.where('name ILIKE ?', r.variant_name).first)
        # puts 'Found variant with its name'.green
      else
        raise 'Cannot find variant with given informations'
      end
      # puts variant.nature.name
      # puts variant.nature.number

      variant.name = r.variant_name unless r.variant_name.blank?
      variant.gtin = r.variant_gtin unless r.variant_gtin.blank?
      variant.unit_name = if variant.has_indicator? :net_mass
                            PALLET_QUANTITY_UNIT_HUMAN_NAME
                          else
                            :unit.tl
                          end
      unless r.variant_variety_reference_name.blank?
        if Nomen::Variety.find(r.variant_variety_reference_name) <= variant.nature.variety
          variant.variety = r.variant_variety_reference_name
        else
          w.info "Cannot use variety of variant because it doesn't descent from nature's one"
        end
      end
      unless r.variant_derivative_of_reference_name.blank?
        if Nomen::Variety.find(r.variant_derivative_of_reference_name) <= variant.nature.derivative_of
          variant.derivative_of = r.variant_derivative_of_reference_name
        else
          w.info "Cannot use derivative_of of variant because it doesn't descent from nature's one"
        end
      end
      variant.active = true if variant.new_record?
      variant.save!
      if variant.has_indicator? :net_mass
        variant.read!(:net_mass, PALLET_QUANTITY_UNIT)
      end

      # create catalog prices
      if r.unit_pretax_amount
        catalog = Catalog.by_default!(:stock)
        item = variant.catalog_items.find_or_initialize_by(catalog: catalog, all_taxes_included: false, currency: Preference[:currency])
        item.amount = r.unit_pretax_amount
        item.save!
        w.info 'OK Stock price for variant created'.green
      end

      variant
    end

    #def find_or_create_sale(entity, address, delivery_address, r)
    def find_or_create_sale(entity, r)
      unless r.created_at && r.invoice_origin_reference_number
        raise 'Missing basic informations on the sale invoice: created_at or number'
      end

      # see if sale exist anyway
      sale = Sale.where('codes ->> ? = ?', FermesLarrere::EUROFLOW_KEY, r.invoice_origin_reference_number).first
      if sale && sale.invoice?
        return nil
      end

      if sale
        sale.invoiced_at = r.created_at || r.updated_at
        sale.created_at = r.created_at
        sale.updated_at = r.updated_at
        #sale.address_id = address.id if address
        #sale.delivery_address_id = delivery_address.id if delivery_address
        #sale.invoice_address_id = address.id if address
        sale.save!

        w.info 'OK Sale updated'.green
      else
        sale = Sale.new(
          invoiced_at: r.created_at,
          created_at: r.created_at,
          updated_at: r.updated_at,
          reference_number: r.invoice_origin_reference_number,
          codes: {
            FermesLarrere::EUROFLOW_KEY => r.invoice_origin_reference_number
          },
          client_id: entity.id,
          letter_format: false,
          nature: SaleNature.actives.first,
          description: "Import from ETL from N° #{r.invoice_origin_reference_number}"
        )

        #sale.address_id = address.id if address
        #sale.delivery_address_id = delivery_address.id if delivery_address
        #sale.invoice_address_id = address.id if address
        sale.save!
        w.info "OK Sale created on #{sale.invoiced_at}".green

        # charge global discount one time if present
        if r.global_discount && r.global_discount.nonzero?
          # check tax for global discount
          global_discount_item_tax = find_or_create_tax(r.global_discount_vat_rate, Preference[:country].to_sym)

          unless global_discount_item_tax
            raise "Cannot find tax for rate: #{r.global_discount_vat_rate}"
          end
          raise 'No variant for global discount' unless global_discount_variant

          item = sale.items.find_or_initialize_by(variant: global_discount_variant, quantity: 1.0)
          item.tax = global_discount_item_tax
          item.unit_pretax_amount = r.global_discount
          item.unit_amount = nil
          item.pretax_amount = nil
          item.amount = nil
          item.save!

          w.info 'OK Global discount on sale created'.green
        end

        # charge consign one time if present
        if r.consign_amount && r.consign_amount.nonzero?
          # check consign_amount
          global_consign_item_tax = Tax.find_by(id: CONSIGN_TAX_ID)
          consign_variant = ProductNatureVariant.find_by(id: CONSIGN_VARIANT_ID)

          raise 'No variant for consign variant' unless consign_variant

          item = sale.items.find_or_initialize_by(variant: consign_variant, quantity: 1.0)
          item.tax = global_consign_item_tax
          item.unit_pretax_amount = r.consign_amount
          item.unit_amount = r.consign_amount
          item.pretax_amount = r.consign_amount
          item.amount = r.consign_amount
          item.save!

          w.info 'OK consign on sale created'.green
        end
      end

      sale
    end

    # Find or create when possible with a parameter which van
    # if id_or_rate is an integer get tax
    # if id_or_rate is a numeric, get tax by rate
    def find_or_create_tax(id_or_rate, country)
      return nil if id_or_rate.blank? || country.blank?
      Tax.find_by(id: id_or_rate.to_i)
    end

    def find_or_create_sale_item(row, sale, variant, sale_line_code)
      return unless row.unit_pretax_amount || row.quantity

      sale_item_tax = find_or_create_tax(row.origin_vat_id, Preference[:country].to_sym)
      unless sale_item_tax
        raise "Cannot determine VAT (id : #{row.origin_vat_id}) for sale item: #{row.invoice_line_origin_reference_number} in invoice #{row.invoice_origin_reference_number}"
      end

      w.info "Sale item tax: #{sale_item_tax.inspect}".red

      # item
      sale_item = nil
      sale_item = sale.items.where('codes ->> ? = ?', FermesLarrere::EUROFLOW_KEY, sale_line_code).first
      sale_item ||= sale.items.new(codes: { FermesLarrere::EUROFLOW_KEY => sale_line_code })

      sale_item.variant = variant

      # get value to convert population from variant
      if variant.has_indicator? :net_mass
        sale_item.quantity = 0.0
        unitary_net_mass_value = variant.reading(:net_mass).value.value.to_f
        unitary_net_mass_unit = variant.reading(:net_mass).value.unit.to_sym

        if unitary_net_mass_value.nonzero?
          sale_item.quantity = row.quantity.in(PALLET_QUANTITY_UNIT_NAME).convert(unitary_net_mass_unit) / unitary_net_mass_value
        end
      end

      sale_item.quantity = row.quantity unless variant.has_indicator? :net_mass
      sale_item.reduction_percentage = row.discount_percentage unless row.discount_percentage.blank?

      sale_item.tax = sale_item_tax
      sale_item.unit_pretax_amount = nil # r.unit_pretax_amount
      sale_item.unit_amount = nil
      sale_item.pretax_amount = row.pretax_amount
      sale_item.amount = nil
      sale_item.compute_from = :pretax_amount
      sale_item.save!

      w.info 'OK Sale item created'.green
      w.info "END - LINE REFERENCE: #{row.invoice_origin_reference_number} - #{row.invoice_line_origin_reference_number} : sale_id(#{sale.id if sale}) / sale_item_id(#{sale_item.id if sale_item})".red
    end

    #def find_or_create_transporter(transporter_code)
      #return nil if transporter_code.blank?
      #entity = Entity.where('codes ->> ? = ?', FermesLarrere::EUROFLOW_KEY, transporter_code).first
      #unless entity
        #entity = Entity.create!(
          #nature: :organization,
          #codes: {
            #FermesLarrere::EUROFLOW_KEY => transporter_code
          #},
          #last_name: transporter_code,
          #active: true,
          #supplier: true,
          #transporter: true
        #)
        #w.info 'OK Transporter entity created'.green
      #end
      #entity
    #end

    def finish_sale(sale, pretax_amount, amount)
      adjust_global_amounts(sale, pretax_amount, amount)
      sale.invoice!
    end

    # Adjusts pretax amount and amount to fit exactly what is given in totals
    # and obtains same tax values in the end
    def adjust_global_amounts(sale, pretax_amount, amount)
      precision = Nomen::Currency.find!(Preference[:currency]).precision
      pretax_amount = pretax_amount.round(precision)
      amount = amount.round(precision)

      if sale.pretax_amount != pretax_amount
        w.info 'Adjust pre-tax amount'
        distribute_on_sale_items(sale, :pretax_amount, pretax_amount, precision)
      end

      if sale.amount != amount
        w.info 'Adjust amount'
        distribute_on_sale_items(sale, :amount, amount, precision)
      end
    end

    # Adjust given column in all items of given sale if they have a nonzero tax
    # amount.
    def distribute_on_sale_items(sale, column, goal, precision)
      sale_value = sale.items.sum(column)
      difference = goal - sale_value

      difference_percentage = 100.0 * (difference / goal).abs
      if difference_percentage > 0.5
        w.info "Round error seems too big to be a round error (#{difference_percentage}%). Items amounts: " + sale.items.pluck(:pretax_amount).sort.to_sentence
      end

      items = {}

      # First pass
      distributable_items = sale.items.where.not(tax: Tax.where(amount: 0))
      distributable_value = distributable_items.sum(column)
      distributable_items.order(column => :desc).pluck(:id, column).each do |id, value|
        new_value = (value + (goal - sale_value) * (value / distributable_value)).round(precision)
        items[id] = new_value
        difference -= (new_value - value)
      end

      # Second pass
      unless difference.zero?
        unit = (difference / difference.abs) * 10**-precision
        w.info unit.to_s.green
        while difference.abs >= 10**-precision
          raise "Difference can't be distributed because we don't have any items on sale #{sale.codes[FermesLarrere::EUROFLOW_KEY]}." unless items.any?
          items.each do |id, _|
            break if difference.zero?
            items[id] += unit
            difference -= unit
          end
        end
      end

      distributable_items.find_each do |item|
        item.update!(column => items[item.id])
      end

      sale.reload
      sale_value = sale.send(column)
      difference = goal - sale_value

      unless difference.abs < 10**-precision
        raise "Sale #{column} (#{sale_value.to_s.yellow}) is not equal with goal (#{goal.to_s.red})\n" + sale.items.pluck(column).sort.to_sentence + "\n" + items.values.sort.to_sentence
      end
    end

    def global_discount_variant
      @global_discount_variant ||= ProductNatureVariant.import_from_nomenclature(:discount_and_reduction)
    end
  end
end