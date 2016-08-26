# coding: utf-8
module CharentesAlliance
  # Incoming deliveries extracted from Charentes Alliance extranet
  class IncomingDeliveriesExchanger < ActiveExchanger::Base
    def import
      here = Pathname.new(__FILE__).dirname

      catalog = Catalog.by_default!(:purchase)
      # TODO: take care of no taxes present before
      Tax.load_defaults unless Tax.any?
      default_tax = Tax.first ||
                    Tax.import_from_nomenclature(:french_vat_normal_2014)
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

      sender_name = 'Charentes Alliance'
      sender = Entity.find_by(last_name: sender_name) ||
               Entity.where('last_name ILIKE ?', sender_name).first ||
               Entity.create!(nature: :organization, last_name: sender_name, supplier: true)

      # map sub_family to product_nature_variant XML Nomenclature

      # add Coop incoming deliveries

      # status to map
      status = {
        'Liquidé' => :order,
        'A livrer' => :estimate,
        'Supprimé' => :aborted
      }

      previous_order_number = nil
      order = nil

      rows = CSV.read(file, encoding: 'UTF-8', col_sep: ';', headers: true)
      w.count = rows.size

      rows.each do |row|
        r = OpenStruct.new(
          order_number: row[0],
          ordered_on: Date.civil(*row[1].to_s.split(/\//).reverse.map(&:to_i)),
          product_nature_name: (variants_transcode[row[3].to_s] || 'common_consumable'),
          matter_name: row[4],
          coop_variant_reference_name: 'coop:' + row[4].downcase.gsub(/[\W\_]+/, '_'),
          coop_reference_name: row[4].to_s,
          quantity: (row[5].blank? ? nil : row[5].tr(',', '.').to_d),
          product_deliver_quantity: (row[6].blank? ? nil : row[6].tr(',', '.').to_d),
          product_unit_price: (row[7].blank? ? nil : row[7].tr(',', '.').to_d),
          order_status: (status[row[8]] || :draft)
        )

        # Create delivery if order_number change and all items concerning the same order are already created.
        if previous_order_number && order && previous_order_number != r.order_number
          delivery = Delivery.create!(
            reference_number: previous_order_number,
            state: :in_preparation,
            started_at: r.ordered_on.to_time,
            stopped_at: r.ordered_on.to_time + 1
          )
          order.delivery_id = delivery.id
          order.save!
          delivery.check
          delivery.start
          delivery.finish
        end

        address = Entity.of_company.default_mail_address ||
                  Entity.of_company.mails.create!(by_default: true)

        # create an order if not exist
        order = Parcel.find_by(reference_number: r.order_number) ||
                Parcel.create!(
                  nature: :incoming,
                  reference_number: r.order_number,
                  planned_at: r.ordered_on,
                  given_at: r.ordered_on,
                  state: :in_preparation,
                  sender: sender,
                  address: address,
                  delivery_mode: :third,
                  storage: building_division
                )
        previous_order_number = r.order_number

        # find a product_nature_variant by mapping current name of matter in coop file in coop reference_name
        unless product_nature_variant = ProductNatureVariant.find_by(number: r.coop_reference_name)
          product_nature_variant ||= if Nomen::ProductNatureVariant.find(r.coop_variant_reference_name)
                                       ProductNatureVariant.import_from_nomenclature(r.coop_variant_reference_name)
                                     else
                                       # find a product_nature_variant by mapping current sub_family of matter in coop file in Ekylibre reference_name
                                       ProductNatureVariant.import_from_nomenclature(r.product_nature_name)
                                     end
          product_nature_variant.number = r.coop_reference_name if r.coop_reference_name
          product_nature_variant.save!
        end
        # Force population_counting to decimal for every product_nature used
        # here
        product_nature_variant.nature.update_columns(population_counting: :decimal)
        # find a price from current supplier for a consider variant
        # TODO: waiting for a product price capitalization method
        catalog_item = catalog.items.find_by(variant_id: product_nature_variant.id)
        catalog_item ||= catalog.items.create!(
          currency: 'EUR',
          reference_tax_id: default_tax.id,
          amount: default_tax.amount_of(r.product_unit_price),
          variant_id: product_nature_variant.id
        )

        if r.order_status == :order
          order.items.create!(
            variant: product_nature_variant,
            product_name: r.matter_name + ' (' + r.ordered_on.l + ')',
            product_identification_number: r.ordered_on.to_s + '_' + r.order_number + '_' + r.matter_name,
            quantity: r.quantity
          )
        end
        w.check_point
      end
    end
  end
end
