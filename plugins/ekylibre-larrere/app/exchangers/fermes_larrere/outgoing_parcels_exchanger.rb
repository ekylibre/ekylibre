# coding: utf-8
module FermesLarrere
  class OutgoingParcelsExchanger < ActiveExchanger::Base
    def import
      rows = Roo::Excelx.new(file)
      w.count = rows.count
      parcel_ids = []
      sale_ids = []
      # unit quantity for variant
      unit_quantity_palette = :kilogram
      unit_quantity_palette_human_name = Nomen::Unit[unit_quantity_palette].human_name
      a = 1.0.in(unit_quantity_palette)

      # get default storehouse
      building_division = BuildingDivision.first ||
                          BuildingDivision.create!(
                            name: 'Default storage',
                            initial_born_at: Date.civil(1, 1, 1),
                            variant: ProductNatureVariant.import_from_nomenclature(:building_division)
                          )
      # set sender
      sender = Entity.of_company
      sender_address = Entity.of_company.default_mail_address ||
                       Entity.of_company.mails.create!(by_default: true)

      rows.each_row_streaming(offset: 1, pad_cells: true) do |row|
        start = Time.now
        m_row = Maybe(row)
        r = {
          # invoice
          invoice_origin_reference_number:        m_row[0].value.map(&:to_s).or_nil,
          invoice_line_origin_reference_number:   m_row[1].value.map(&:to_s).or_nil,
          created_at:                             (row[2].blank? ? nil : Time.parse(row[2].value.to_s)),
          updated_at:                             (row[3].blank? ? nil : Time.parse(row[3].value.to_s)),
          # client
          client_code:                            m_row[4].value.map(&:to_s).or_nil,
          client_full_name:                       m_row[5].value.map(&:to_s).strip.or_nil,
          client_adress_name:                     m_row[6].value.map(&:to_s).strip.or_nil,
          client_town_name:                       m_row[7].value.map(&:to_s).strip.or_nil,
          client_postal_code_name:                m_row[8].value.map(&:to_s).strip.or_nil,
          client_country_code:                    m_row[9].value.map(&:to_s).downcase.or_nil,
          client_phone_number:                    m_row[10].value.map(&:to_s).strip.or_nil,
          client_fax_number:                      m_row[11].value.map(&:to_s).strip.or_nil,
          client_email:                           m_row[12].value.map(&:to_s).strip.or_nil,
          client_vat_number:                      m_row[13].value.map(&:to_s).strip.delete(' ').or_nil,
          client_siret_number:                    m_row[14].value.map(&:to_s).strip.delete(' ').or_nil,
          client_account_number:                  m_row[15].value.map(&:to_s).strip.delete(' ').or_nil,
          # invoice adress
          client_invoice_adress_code:             m_row[16].value.map(&:to_s).or_nil,
          client_invoice_full_name:               m_row[17].value.map(&:to_s).strip.or_nil,
          client_invoice_adress_name:             m_row[18].value.map(&:to_s).strip.or_nil,
          client_invoice_town_name:               m_row[19].value.map(&:to_s).strip.or_nil,
          client_invoice_postal_code_name:        m_row[20].value.map(&:to_s).strip.or_nil,
          client_invoice_country_code:            m_row[21].value.map(&:to_s).downcase.or_nil,
          client_transporter_code:                m_row[22].value.map(&:to_s).or_nil,
          # variant
          variant_gtin:                           m_row[23].value.map(&:to_s).or_nil,
          variant_nature_reference_name:          m_row[24].value.map(&:to_s).or_nil,
          variant_variety_reference_name:         m_row[25].value.map(&:to_s).or_nil,
          variant_derivative_of_reference_name:   m_row[26].value.map(&:to_s).or_nil,
          variant_name:                           m_row[27].value.map(&:to_s).or_nil,
          quantity:                               (m_row[28].value.zero?.or_nil ? nil : row[28].value.to_d.round(2)),
          unit_pretax_amount:                     m_row[29].value.to_d.or_nil,
          discount_percentage:                    m_row[30].value.to_d.or_nil,
          origin_vat_rate:                        m_row[31].value.to_d.or_nil,
          transport_fee:                          m_row[32].value.to_d.or_nil,
          global_discount:                        m_row[33].value.to_d.or_nil,
          global_discount_vat_rate:               m_row[34].value.to_d.or_nil,
          origin_num_piece:                       m_row[35].value.map(&:to_s).or_nil,
          origin_code_lot:                        m_row[36].value.map(&:to_s).or_nil,
          origin_num_palette:                     m_row[37].value.map(&:to_s).or_nil,
          quantity_palette:                       (m_row[38].value.zero?.or_nil ? nil : row[38].value.to_d.round(2))
          # Extra infos
          # document_reference_number: "#{Date.parse(row[0].to_s)}_#{row[1]}_#{row[2]}".tr(' ', '-')
        }.to_struct
        w.info "LINE REFERENCE : #{r.invoice_origin_reference_number} - #{r.invoice_line_origin_reference_number}".red

        sale_line_code = r.invoice_origin_reference_number.to_s + '-' + r.invoice_line_origin_reference_number.to_s

        unless Nomen::Country.find(r.client_country_code)
          r.client_country_code = Preference[:country]
        end

        unless Nomen::Country.find(r.client_invoice_country_code)
          r.client_invoice_country_code = Preference[:country]
        end

        # find or initialize an entity
        entity = nil
        if r.client_code
          entity = Entity.where('codes ->> ? = ?', FermesLarrere::EUROFLOW_KEY, r.client_code).first
          unless entity
            entity = Entity.new
            entity.nature = :organization
            entity.codes = { FermesLarrere::EUROFLOW_KEY => r.client_code }
            entity.active = true
            entity.client = true
            w.info 'OK Entity created'.green
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
          # entity.client_account = Account.find_or_create_by_number(r.client_account_number, name: person.full_name)
          entity.save!
          w.info 'OK Entity updated'.green
        end

        address = nil
        # Add mail address if given
        if r.client_full_name && r.client_adress_name && r.client_town_name && r.client_postal_code_name
          line_1 = r.client_full_name
          line_4 = r.client_adress_name
          line_6 = r.client_postal_code_name + ' ' + r.client_town_name
          address = entity.mails.where('mail_line_4 ILIKE ? AND mail_line_6 ILIKE ? AND mail_line_1 ILIKE ?', line_4, line_6, line_1).where(mail_country: r.client_country_code).first
          unless address
            address = entity.mails.create!(mail_line_1: line_1, mail_line_4: line_4, mail_line_6: line_6, mail_country: r.client_country_code)
            w.info 'OK Mail adress created'.green
          end
        end

        delivery_address = nil
        # Add invoice mail address if given
        if r.client_invoice_full_name && r.client_invoice_adress_name && r.client_invoice_town_name && r.client_invoice_postal_code_name
          line_1 = r.client_invoice_full_name
          line_4 = r.client_invoice_adress_name
          line_6 = r.client_invoice_postal_code_name + ' ' + r.client_invoice_town_name
          delivery_address = entity.mails.where('mail_line_4 ILIKE ? AND mail_line_6 ILIKE ? AND mail_line_1 ILIKE ?', line_4, line_6, line_1).where(mail_country: r.client_invoice_country_code).first
          w.info 'OK Invoice mail adress exist'.green if delivery_address
          unless delivery_address
            delivery_address = entity.mails.create!(mail_line_1: line_1, mail_line_4: line_4, mail_line_6: line_6, mail_country: r.client_invoice_country_code)
            w.info 'OK Invoice mail adress created'.green
          end
        end

        # find or import a variant
        variant = nil
        if r.variant_gtin && r.variant_name
          w.info 'VARIANT--------'.yellow
          variant = ProductNatureVariant.find_by(gtin: r.variant_gtin)
          naming_variant = ProductNatureVariant.where('name ILIKE ?', r.variant_name).first
          # case 1 : variant already exist with GTIN
          if variant && r.variant_name
            w.info 'case 1--------'.yellow
            variant.name = r.variant_name
            variant.variety = r.variant_variety_reference_name
            variant.derivative_of = r.variant_derivative_of_reference_name if r.variant_derivative_of_reference_name
            variant.unit_name = unit_quantity_palette_human_name
            variant.read!(:net_mass, a)
            variant.save!
            w.info 'OK GTIN existing Variant updated'.green
          # case 2 : variant already exist with NAME
          elsif naming_variant
            w.info 'case 2--------'.yellow
            variant = naming_variant
            variant.name = r.variant_name
            variant.unit_name = unit_quantity_palette_human_name
            variant.variety = r.variant_variety_reference_name
            variant.derivative_of = r.variant_derivative_of_reference_name if r.variant_derivative_of_reference_name
            variant.gtin = r.variant_gtin
            variant.read!(:net_mass, a)
            variant.save!
            w.info 'OK Naming existing Variant updated'.green
            # create catalog stock prices
            if r.unit_pretax_amount
              catalog = Catalog.by_default!(:stock)
              unless variant.catalog_items.where(catalog: catalog, all_taxes_included: false, amount: r.unit_pretax_amount).empty?
                variant.catalog_items.create!(catalog: catalog, all_taxes_included: false, amount: r.unit_pretax_amount, currency: Preference[:currency])
                w.info 'OK Stock price for variant created'.green
              end
            end
          # case 3 : variant doesn't exist
          elsif r.variant_name && r.variant_gtin && r.variant_variety_reference_name && r.variant_nature_reference_name
            w.info 'case 3--------'.yellow
            # transcode to have the right reference name to import variant
            nature = ProductNature.find_by(reference_name: r.variant_nature_reference_name)
            unless nature
              if Nomen::ProductNature.find(r.variant_nature_reference_name.to_sym)
                nature = ProductNature.import_from_nomenclature(r.variant_nature_reference_name.to_sym)
              end
            end
            # create variant
            variant = nature.variants.new(
              name: r.variant_name,
              gtin: r.variant_gtin,
              variety: r.variant_variety_reference_name,
              active: true,
              unit_name: unit_quantity_palette_human_name
            )
            variant.read!(:net_mass, a)
            variant.derivative_of = r.variant_derivative_of_reference_name if r.variant_derivative_of_reference_name
            variant.save!
            w.info 'OK Variant created'.green

            # create catalog prices
            if r.unit_pretax_amount
              catalog = Catalog.by_default!(:stock)
              if variant.catalog_items.where(catalog: catalog, all_taxes_included: false, amount: r.unit_pretax_amount).empty?
                variant.catalog_items.create!(catalog: catalog, all_taxes_included: false, amount: r.unit_pretax_amount, currency: Preference[:currency])
                w.info 'OK Stock price for variant created'.green
              end
            end

          end
        end

        # find a sale
        sale = nil
        description = nil
        if entity && r.invoice_origin_reference_number
          # see if sale exist anyway
          sale = Sale.where('codes ->> ? = ?', FermesLarrere::EUROFLOW_KEY, r.invoice_origin_reference_number).first
          w.info 'OK Sale found'.green if sale
          sale_ids << sale.id if sale
        end

        # find a sale line
        sale_item = nil
        if sale && variant && sale_line_code
          sale_item = SaleItem.where('codes ->> ? = ?', FermesLarrere::EUROFLOW_KEY, sale_line_code).first
          w.info 'OK Sale item found'.green if sale_item
        end

        if r.client_transporter_code
          transporter_entity = Entity.where('codes ->> ? = ?', FermesLarrere::EUROFLOW_KEY, r.client_transporter_code).first
          unless transporter_entity
            transporter_entity = Entity.new
            transporter_entity.nature = :organization
            transporter_entity.codes = { FermesLarrere::EUROFLOW_KEY => r.client_transporter_code }
            transporter_entity.last_name = r.client_transporter_code
            transporter_entity.active = true
            transporter_entity.supplier = true
            transporter_entity.transporter = true
            transporter_entity.save!
            w.info 'OK Transporter entity created'.green
          end
        end

        parcel = nil
        # create parcel
        if r.origin_num_piece && transporter_entity && entity && delivery_address
          # create an parcel
          parcel = Parcel.find_by(reference_number: r.origin_num_piece)
          next if parcel && parcel.given?
          if parcel
            w.info 'OK Parcel found'.green
          else
            parcel = Parcel.create!(
              nature: :outgoing,
              reference_number: r.origin_num_piece,
              planned_at: r.created_at,
              given_at: r.created_at,
              state: :in_preparation,
              sender: sender,
              address: delivery_address,
              recipient: entity,
              delivery_mode: :transporter,
              transporter: transporter_entity,
              storage: building_division
            )
            parcel_ids << parcel.id
            w.info 'OK Parcel created'.green
          end
          parcel.update(sale_id: sale.id) if sale
        end

        tracking = nil
        # get tracking or create it
        if r.origin_code_lot
          tracking = Tracking.find_by(serial: r.origin_code_lot) ||
                     Tracking.create!(
                       serial: r.origin_code_lot,
                       name: variant.name
                     )
        end

        product = nil
        # build name
        name = ''
        name << variant.variety.human_name
        name << ' ' + variant.derivative_of.human_name if variant.derivative_of
        name << ' - Conditionné(e)'

        # get product or create it

        if tracking && variant
          pmodel = variant.nature.matching_model
          product = Product.find_by(variant: variant, tracking: tracking) ||
                    pmodel.create!(
                      name: name,
                      initial_born_at: r.created_at,
                      initial_population: 0.0,
                      variant: variant,
                      tracking: tracking
                    )
        end

        parcel_item = nil
        # create parcel item
        if parcel && product && r.origin_num_palette && r.quantity_palette
          # create an parcel
          parcel_item = parcel.items.find_by(product_identification_number: r.origin_num_palette)
          next if parcel_item && parcel_item.parcel.given?
          # get value to convert population from product
          qty = 0.0
          unitary_net_mass_value = product.variant.reading(:net_mass).value.value.to_f
          unitary_net_mass_unit = product.variant.reading(:net_mass).value.unit.to_sym
          qty = (r.quantity_palette.in(unit_quantity_palette).convert(unitary_net_mass_unit) / unitary_net_mass_value) if unitary_net_mass_value != 0.0
          unless parcel_item
            parcel_item = parcel.items.create!(
              source_product: product,
              quantity: qty.to_d,
              product_identification_number: r.origin_num_palette
            )
            w.info "OK Parcel item created with #{qty.to_d}".green
          end

          parcel_item.update(sale_item: sale_item) if sale_item
        end

        w.info "END - LINE REFERENCE : #{r.invoice_origin_reference_number} - #{tracking.serial if tracking} : parcel_id(#{parcel.id if parcel}) / parcel_item_id(#{parcel_item.id if parcel_item})".red

        w.check_point
      end

      # Restart counting
      w.info '--STEP 2 - START - Check parcel to give'.yellow
      added_parcels = Parcel.where(id: parcel_ids.compact.uniq)
      w.reset! added_parcels.count, :yellow

      # change status of all new added parcels
      added_parcels.each do |parcel|
        next w.check_point if parcel.given?
        parcel.order if parcel.draft?
        # parcel.prepare if parcel.can_prepare?
        parcel.give
        w.info "#{parcel.number} of state #{parcel.state}".green
        w.check_point
      end
      w.info '--STEP 2 - END - Check parcel to give'.yellow

      # Restart counting
      w.info '--STEP 3 - START - Check sale to invoice'.yellow
      added_sales = Sale.where(id: sale_ids.compact.uniq)
      w.reset! added_sales.count, :yellow

      # change status of all new linked sales
      added_sales.each do |sale|
        unless sale.invoice?
          sale.propose if sale.draft?
          sale.confirm
          sale.invoice(sale.invoiced_at)
          w.info "#{sale.number} of state #{sale.state}".green
        end
        w.check_point
      end
      w.info '--STEP 3 - END - Check sale to invoice'.yellow
    end
  end
end
