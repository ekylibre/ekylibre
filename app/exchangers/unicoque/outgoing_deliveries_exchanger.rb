class Unicoque::OutgoingDeliveriesExchanger < ActiveExchanger::Base

  def import
    here = Pathname.new(__FILE__).dirname

    varieties_transcode = {}.with_indifferent_access
    CSV.foreach(here.join("varieties.csv"), headers: true) do |row|
      varieties_transcode[row[0]] = row[1].to_sym
    end

    # create entity corresponding to the cooperative
    cooperative = Entity.find_by_last_name("Unicoque")
    unless cooperative = Entity.where("LOWER(full_name) LIKE ?", "%Unicoque%".mb_chars.downcase).first
      cooperative = Entity.create!(last_name: "Unicoque",
                                   nature: :organization,
                                   supplier: false, client: true,
                                   mails_attributes: {
                                     0 => {
                                       canal: "mail",
                                       mail_line_4: "Lamouthe",
                                       mail_line_6: "47290 La Cancon",
                                       mail_country: :fr
                                     }
                                   },
                                   emails_attributes: {
                                     0 => {
                                       canal: "email",
                                       coordinate: "contact@unicoque.com"
                                     }
                                   })
    end

    rows = CSV.read(file, encoding: "UTF-8", col_sep: ";", headers: true).delete_if{|r| r[0].blank?}
    w.count = rows.size

    rows.each do |row|
      r = OpenStruct.new(year: row[0].to_i,
                         name: row[3].to_s + ' ' + row[5].to_s + ' - ' + row[0].to_s,
                         variety: (row[4].blank? ? nil : varieties_transcode[row[4].to_s]),
                         variety_radical_code: (row[4].blank? ? nil : row[4].to_s.at(0..1)),
                         harvest_area_sna: (row[6].blank? ? nil : row[6].gsub(",",".").to_d),
                         harvest_area_sea: (row[7].blank? ? nil : row[7].gsub(",",".").to_d),
                         total_quantity_in_kg: (row[8].blank? ? nil : row[8].gsub(",",".").to_d),
                         total_value_in_euro: (row[10].blank? ? nil : row[10].gsub(",",".").to_d)
                        )


      born_at = (row[0].to_s + "-09-01 00:00").to_datetime
      variant_reference = (r.variety_radical_code == '21' ? :hazelnut : :walnut)

      # Find or import from variety and derivative_of the good ProductNatureVariant
      variant = ProductNatureVariant.find_or_import!(variant_reference, options = { derivative_of: r.variety}).first
      # Or import from generic variety the good ProductNatureVariant
      variant ||= ProductNatureVariant.import_from_nomenclature(variant_reference)

      pmodel = variant.nature.matching_model
      # find the container
      #unless container = Product.first #find_by_work_number(r.cultivable_zone_code)
      #  raise "No container for cultivation!"
      #end

      # create the product
      product = pmodel.create!(:variant_id => variant.id,
                               :work_number =>  r.year.to_s + "_" + r.variety.to_s,
                               :name => r.name,
                               :initial_born_at => born_at,
                               :initial_owner => Entity.of_company,
                               :derivative_of => r.variety
                               #, :initial_container => container
                              )

      # create indicators linked to product
      product.read!(:population, r.total_quantity_in_kg, at: r.born_at) if r.total_quantity_in_kg


      # set a price from current cooperative for the consider variant
      catalog = Catalog.find_by_code("VENTE")
      sale_price_template_tax = Tax.find_by_reference_name('french_vat_reduced')
      product_unit_price = (r.total_value_in_euro / r.total_quantity_in_kg).to_f

      unless catalog.items.where(variant_id: variant.id).any?
        catalog.items.create!(:variant_id => variant.id,
                              :currency => "EUR",
                              :reference_tax_id => sale_price_template_tax.id,
                              :amount => sale_price_template_tax.amount_of(product_unit_price)
                             )
      end

      # create an outgoing_delivery from company to cooperative
      outgoing_delivery = OutgoingDelivery.create!(mode: :delivered_at_place,
                                                   address: cooperative.default_mail_address,
                                                   recipient: cooperative,
                                                   sent_at: born_at,
                                                   with_transport: false
                                                  )
      # link item to outgoing_delivery
      outgoing_delivery.items.create!(product: product)

      w.check_point
    end
  end

end
