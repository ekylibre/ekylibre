# coding: utf-8
class CharentesAlliance::IncomingDeliveriesExchanger < ActiveExchanger::Base
  def import
    here = Pathname.new(__FILE__).dirname

    catalog = Catalog.find_by_code('ACHAT') || Catalog.first
    supplier_account = Account.find_or_import_from_nomenclature(:suppliers)
    # TODO: take care of no taxes present before
    Tax.load_defaults unless Tax.any?
    appro_price_template_tax = Tax.first
    building_division = BuildingDivision.first
    suppliers = Entity.where(of_company: false, supplier: true).reorder(:supplier_account_id, :last_name)
    suppliers ||= Entity.create!(sale_catalog_id: catalog.id, nature: :organization, language: 'fra', last_name: 'All', supplier_account_id: supplier_account.id, currency: 'EUR', supplier: true)

    variants_transcode = {}.with_indifferent_access
    CSV.foreach(here.join('variants.csv'), headers: true) do |row|
      variants_transcode[row[0]] = row[1].to_sym
    end

    cooperative = Entity.find_by_last_name('CHARENTES ALLIANCE') || Entity.find_by_last_name('Charentes Alliance')

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
        product_nature_name: (variants_transcode[row[3].to_s] || 'small_equipment'),
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
        delivery = Delivery.create!(reference_number: previous_order_number, state: :in_preparation, started_at: r.ordered_on.to_time, stopped_at: r.ordered_on.to_time + 1)
        order.delivery_id = delivery.id
        order.save!
        delivery.check
        delivery.start
        delivery.finish
      end

      # create an order if not exist
      unless order = Parcel.find_by_reference_number(r.order_number)
        order = Parcel.create!(nature: :incoming, reference_number: r.order_number, planned_at: r.ordered_on, given_at: r.ordered_on, state: :in_preparation, sender: cooperative, address: Entity.of_company.default_mail_address, delivery_mode: :third, storage: building_division)
        previous_order_number = r.order_number
      end
      # find a product_nature_variant by mapping current name of matter in coop file in coop reference_name
      unless product_nature_variant = ProductNatureVariant.find_by_number(r.coop_reference_name)
        product_nature_variant ||= if Nomen::ProductNatureVariant.find(r.coop_variant_reference_name)
                                     ProductNatureVariant.import_from_nomenclature(r.coop_variant_reference_name)
                                   else
                                     # find a product_nature_variant by mapping current sub_family of matter in coop file in Ekylibre reference_name
                                     ProductNatureVariant.import_from_nomenclature(r.product_nature_name)
                                   end
        product_nature_variant.number = r.coop_reference_name if r.coop_reference_name
        product_nature_variant.save!
      end
      # find a price from current supplier for a consider variant
      #  @ TODO waiting for a product price capitalization method
      product_nature_variant_price = catalog.items.find_by(variant_id: product_nature_variant.id)
      product_nature_variant_price ||= catalog.items.create!(
        currency: 'EUR',
        reference_tax_id: appro_price_template_tax.id,
        amount: appro_price_template_tax.amount_of(r.product_unit_price),
        variant_id: product_nature_variant.id
      )
      product_model = product_nature_variant.nature.matching_model
      incoming_item ||= product_model.create!(variant: product_nature_variant, work_number: r.ordered_on.to_s + '_' + r.matter_name, name: r.matter_name + ' (' + r.ordered_on.to_s + ')', initial_owner: Entity.of_company, identification_number: r.ordered_on.to_s + '_' + r.order_number + '_' + r.matter_name, initial_born_at: r.ordered_on, created_at: r.ordered_on, default_storage: building_division, initial_population: r.quantity)

      # incoming_item.move!(r.quantity, at: r.ordered_on.to_datetime)

      if incoming_item.present? && r.order_status == :order
        order.items.create!(source_product: incoming_item, product: incoming_item)
      end
      w.check_point
    end
  end
end
