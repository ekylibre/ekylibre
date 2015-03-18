# coding: utf-8
# Create or updates animals
Exchanges.add_importer :charentes_alliance_incoming_deliveries do |file, w|

  here = Pathname.new(__FILE__).dirname
  
  catalog = Catalog.find_by_code("ACHAT") || Catalog.first
  supplier_account = Account.find_or_create_in_chart(:suppliers)
  appro_price_template_tax = Tax.first
  building_division = BuildingDivision.first
  suppliers = Entity.where(:of_company => false, :supplier => true).reorder(:supplier_account_id, :last_name)
  suppliers ||= LegalEntity.create!(:sale_catalog_id => catalog.id, :nature => "company", :language => "fra", :last_name => "All", :supplier_account_id => supplier_account.id, :currency => "EUR", :supplier => true)

  variants_transcode = {}.with_indifferent_access
  CSV.foreach(here.join("variants.csv"), headers: true) do |row|
    variants_transcode[row[0]] = row[1].to_sym
  end

  cooperative = Entity.find_by_last_name("CHARENTES ALLIANCE")

  # map sub_family to product_nature_variant XML Nomenclature
  
  # add Coop incoming deliveries
  
  # status to map
  status = {
    "Liquidé" => :order,
    "A livrer" => :estimate,
    "Supprimé" => :aborted
  }

  rows = CSV.read(file, encoding: "UTF-8", col_sep: ";", headers: true)
  w.count = rows.size
  
  rows.each do |row|
    r = OpenStruct.new(:order_number => row[0],
                       :ordered_on => Date.civil(*row[1].to_s.split(/\//).reverse.map(&:to_i)),
                       :product_nature_name => (variants_transcode[row[3].to_s] || "small_equipment"),
                       :matter_name => row[4],
                       :coop_variant_reference_name => "coop:" + row[4].downcase.gsub(/[\W\_]+/, '_'),
                       :quantity => (row[5].blank? ? nil : row[5].to_d),
                       :product_deliver_quantity => (row[6].blank? ? nil : row[6].to_d),
                       :product_unit_price => (row[7].blank? ? nil : row[7].to_d),
                       :order_status => (status[row[8]] || :draft)
                      )
    # create an incoming deliveries if not exist and status = 2
    if r.order_status == :order
      order   = IncomingDelivery.find_by_reference_number(r.order_number)
      order ||= IncomingDelivery.create!(reference_number: r.order_number, received_at: r.ordered_on, sender: cooperative, address: Entity.of_company.default_mail_address, mode: :ex_works)
      # find a product_nature_variant by mapping current name of matter in coop file in coop reference_name
      unless product_nature_variant = ProductNatureVariant.find_by_reference_name(r.coop_variant_reference_name)
        if Nomen::ProductNatureVariants.find(r.coop_variant_reference_name)
          product_nature_variant ||= ProductNatureVariant.import_from_nomenclature(r.coop_variant_reference_name)
        end
        # find a product_nature_variant by mapping current sub_family of matter in coop file in Ekylibre reference_name
        product_nature_variant ||= ProductNatureVariant.import_from_nomenclature(r.product_nature_name)
      end
      # find a price from current supplier for a consider variant
      # @ TODO waiting for a product price capitalization method
      product_nature_variant_price = catalog.items.find_by(variant_id: product_nature_variant.id)
      product_nature_variant_price ||= catalog.items.create!(:currency => "EUR",
                                                             :reference_tax_id => appro_price_template_tax.id,
                                                             :amount => appro_price_template_tax.amount_of(r.product_unit_price),
                                                             :variant_id => product_nature_variant.id
                                                            )

      product_model = product_nature_variant.nature.matching_model
      incoming_item ||= product_model.create!(:variant => product_nature_variant, :name => r.matter_name + " " + r.ordered_on.to_s, :initial_owner => Entity.of_company, :identification_number => r.order_number, :initial_born_at => r.ordered_on, :created_at => r.ordered_on, :default_storage => building_division)
      unless incoming_item.frozen_indicators_list.include?(:population)
        incoming_item.read!(:population, r.quantity, :at => r.ordered_on.to_datetime)
      end

      if incoming_item.present?
        order.items.create!(product: incoming_item, container: building_division)
      end
    end

    w.check_point
  end

end
