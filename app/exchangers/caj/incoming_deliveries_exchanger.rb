module Caj
  # Incoming deliveries extracted from Charentes Alliance extranet
  class IncomingDeliveriesExchanger < ActiveExchanger::Base
    category :stocks
    vendor :caj

    def import
      here = Pathname.new(__FILE__).dirname

      purchase_catalog = Catalog.by_default!(:purchase, currency: 'EUR')
      stock_catalog = Catalog.by_default!(:stock, currency: 'EUR')
      building_division = BuildingDivision.first ||
                          BuildingDivision.create!(
                            name: 'Default storage',
                            initial_born_at: Date.civil(1, 1, 1),
                            variant: ProductNatureVariant.import_from_nomenclature(:building_division)
                          )

      variants_transcode = {}.with_indifferent_access
      CSV.foreach(here.join('variants.csv'), headers: true) do |row|
        variants_transcode[row[0]] = row[1].to_sym
      end

      units_transcode = {}.with_indifferent_access
      CSV.foreach(here.join('units.csv'), headers: true) do |row|
        units_transcode[row[0]] = row[1].to_sym
      end

      sender_name = 'Coopérative Agricole de Juniville'
      sender = Entity.find_by(last_name: sender_name) ||
               Entity.where('last_name ILIKE ?', sender_name).first ||
               Entity.create!(nature: :organization, last_name: sender_name, supplier: true)

      address = Entity.of_company.default_mail_address ||
                Entity.of_company.mails.create!(by_default: true)

      # map sub_family to product_nature_variant XML Nomenclature

      # add Coop incoming deliveries

      # status to map

      previous_parcel_number = nil
      parcel = nil
      entries = []

      rows = CSV.read(file, encoding: 'UTF-8', col_sep: ';', headers: true)
      w.count = rows.size

      rows.sort_by(&:first).each do |row|
        r = OpenStruct.new(
          parcel_number: row[0].to_s,
          ordered_on: Date.parse(row[1].to_s),
          product_nature_name: (variants_transcode[row[2].to_s.strip] || 'common_consumable'),
          coop_reference_number: row[3].to_s.strip,
          coop_reference_name: row[4].to_s.downcase.strip,
          quantity: (row[5].blank? ? nil : row[5].tr(',', '.').to_d),
          unity: units_transcode[row[6].to_s],
          product_unit_price: (row[7].blank? ? nil : row[7].tr(',', '.').to_d),
          pretax_amount: (row[8].blank? ? nil : row[8].tr(',', '.').to_d)
        )

        # create an parcel if not exist
        parcel = Reception.find_by(reference_number: r.parcel_number, currency: 'EUR', nature: :incoming) ||
                 Reception.create!(
                   nature: :incoming,
                   currency: 'EUR',
                   reference_number: r.parcel_number,
                   planned_at: r.ordered_on,
                   given_at: r.ordered_on,
                   state: :draft,
                   sender: sender,
                   address: address,
                   delivery_mode: :third,
                   storage: building_division
                 )
        entries << r.parcel_number

        # try to find the correct variant from id of provider
        product_nature_variant = ProductNatureVariant.where('providers ->> ? = ?', sender.id, r.coop_reference_number).first
        # try to find the correct variant from name
        product_nature_variant ||= ProductNatureVariant.where('name ILIKE ?', r.coop_reference_name).first
        # create the variant
        unless product_nature_variant
          product_nature_variant = ProductNatureVariant.import_from_nomenclature(r.product_nature_name, true)
          product_nature_variant.providers = { sender.id => r.coop_reference_number } if r.coop_reference_number
          product_nature_variant.name = r.coop_reference_name if r.coop_reference_name
          product_nature_variant.save!
        end
        # Force population_counting to decimal for every product_nature used
        # here
        product_nature_variant.nature.update_columns(population_counting: :decimal)
        # find a price from current supplier for a consider variant
        # TODO: waiting for a product price capitalization method
        if r.product_unit_price.to_d > 0.0
          catalog_item = purchase_catalog.items.find_or_initialize_by(variant_id: product_nature_variant.id)
          catalog_item.amount = r.product_unit_price
          catalog_item.save!
        end

        # if r.parcel_status == :given
        item = parcel.items.build(variant: product_nature_variant)
        item.product_name = r.coop_reference_name + ' (' + r.ordered_on.l + ')'
        item.product_identification_number = r.ordered_on.to_s + '_' + r.parcel_number + '_' + r.coop_reference_number
        item.quantity = r.quantity
        item.unit_pretax_amount = r.product_unit_price
        item.save!
        item.storings.create!(storage_id: building_division.id, quantity: r.quantity)
        w.check_point
      end

      entries.compact.uniq.each do |parcel_number|
        p = Reception.find_by(reference_number: parcel_number)
        p.give
      end
    end
  end
end
