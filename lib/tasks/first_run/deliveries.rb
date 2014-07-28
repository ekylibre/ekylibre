# -*- coding: utf-8 -*-
load_data :deliveries do |loader|

  #############################################################################
  # import Coop Order to make automatic purchase

  catalog = Catalog.find_by_code("ACHAT") || Catalog.first
  supplier_account = Account.find_or_create_in_chart(:suppliers)
  appro_price_template_tax = Tax.first
  building_division = BuildingDivision.first
  suppliers = Entity.where(:of_company => false, :supplier => true).reorder(:supplier_account_id, :last_name)
  suppliers ||= LegalEntity.create!(:sale_catalog_id => catalog.id, :nature => "company", :language => "fra", :last_name => "All", :supplier_account_id => supplier_account.id, :currency => "eur", :supplier => true)


  variants_transcode = {}.with_indifferent_access

  file = loader.path("charentes_alliance", "variants_transcode.csv")
  if file.exist?
    CSV.foreach(file, headers: true) do |row|
      variants_transcode[row[0]] = row[1].to_sym
    end
  end

  # @TODO refactorize to make import for n entities
  file = loader.path("charentes_alliance", "appros.csv")
  if file.exist?

    cooperative = Entity.find_by_last_name("Charentes Alliance")

    loader.count :cooperative_incoming_deliveries do |w|
      # map sub_family to product_nature_variant XML Nomenclature

      # add Coop incoming deliveries

      # status to map
      status = {
        "Liquidé" => :order,
        "A livrer" => :estimate,
        "Supprimé" => :aborted
      }

      CSV.foreach(file, :encoding => "UTF-8", :col_sep => ";", :headers => true) do |row|
        r = OpenStruct.new(:order_number => row[0],
                           :ordered_on => Date.civil(*row[1].to_s.split(/\//).reverse.map(&:to_i)),
                           :product_nature_name => (variants_transcode[row[3].to_s] || "small_equipment"),
                           :matter_name => row[4],
                           :coop_variant_reference_name => "coop:" + row[4].downcase.gsub(/\W+/, '_'),
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
          product_nature_variant_price = catalog.prices.find_by(variant_id: product_nature_variant.id, amount: r.product_unit_price)
          product_nature_variant_price ||= catalog.prices.create!(:started_at => r.ordered_on,
                                                                  :currency => "EUR",
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
  end


  ##############################################################################
  ## Demo data for document                                                   ##
  ##############################################################################
  # @FIXME : not working on my xubuntu 13.10 x64
  #file = loader.path("alamano", "documents", "releve_apports.pdf")
  #if file.exist?
  #  loader.count :numerize_outgoing_deliveries do |w|
      # import an outgoing_deliveries_journal in PDF
      # bug in demo server for instance
  #    document = Document.create!(key: "20130724_outgoing_001", name: "apport-20130724", nature: "outgoing_deliveries_journal")
  #    File.open(file, "rb:ASCII-8BIT") do |f|
  #      document.archive(f.read, :pdf)
  #    end
  #  end
  #end


  # loader.count :cooperative_outgoing_deliveries do |w|
  #   # #############################################################################
  #   # # import Coop Deliveries to make automatic sales
  #   # # @TODO finish with two level (sales and sales_lines)
  #   # @TODO make some correction for act_as_numbered
  #   # # set the coop
  #   # print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] OutgoingDelivery - Charentes Alliance Coop Delivery (Apport) 2013: "
  #   # clients = Entity.where(:of_company => false).reorder(:client_account_id, :last_name) # .where(" IS NOT NULL")
  #   # coop = clients.offset((clients.count/2).floor).first
  #   # unit_u = Unit.get(:u)
  #   # # add a Coop sale_nature
  #   # sale_nature   = SaleNature.actives.first
  #   # sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => "EUR", :active => true)
  #   # # Asset Code
  #   # sale_account_nature_coop = Account.find_by_number("701")
  #   # stock_account_nature_coop = Account.find_by_number("321")

  #   # file = loader.path("coop-apport.csv")
  #   # CSV.foreach(file, :encoding => "UTF-8", :col_sep => ";", :headers => false, :quote_char => "'") do |row|
  #   #   r = OpenStruct.new(:delivery_number => row[0],
  #   #                      :delivered_on => Date.civil(*row[1].to_s.split(/\//).reverse.map(&:to_i)),
  #   #                      :delivery_place => row[2],
  #   #                      :product_nature_name => row[3],
  #   #                      :product_net_mass => row[4].to_d,
  #   #                      :product_standard_mass => row[5].to_d,
  #   #                      :product_humidity => row[6].to_d,
  #   #                      :product_impurity => row[7].to_d,
  #   #                      :product_specific_mass => row[8].to_d,
  #   #                      :product_proteins => row[9].to_d,
  #   #                      :product_cal => row[10].to_d,
  #   #                      :product_mad => row[11].to_d,
  #   #                      :product_grade => row[12].to_d,
  #   #                      :product_expansion => row[13].to_d
  #   #                      )
  #   #   # create a purchase if not exist
  #   #   sale   = Sale.find_by_reference_number(r.delivery_number)
  #   #   sale ||= Sale.create!(:state => r.order_status, :currency => "EUR", :nature_id => purchase_nature.id, :reference_number => r.order_number, :supplier_id => coop.id, :planned_on => r.ordered_on, :created_on => r.ordered_on)
  #   #   tax_price_nature_appro = Tax.find_by_amount(19.6)
  #   #   # create a product_nature if not exist
  #   #   product_nature   = ProductNature.find_by_name(r.product_nature_name)
  #   #   product_nature ||= ProductNature.create!(:stock_account_id => stock_account_nature_coop.id, :charge_account_id => charge_account_nature_coop.id, :name => r.product_nature_name, :number => r.product_nature_name,  :saleable => false, :purchasable => true, :active => true, :storable => true, :variety_id => b.id, :unit_id => unit_u.id, :category_id => ProductNatureCategory.by_default.id)
  #   #   # create a product (Matter) if not exist
  #   #   product   = Matter.find_by_name(r.matter_name)
  #   #   product ||= Matter.create!(:name => r.matter_name, :identification_number => r.matter_name, :work_number => r.matter_name, :initial_born_at => Time.now, :nature_id => product_nature.id, :owner_id => Entity.of_company.id, :number => r.matter_name) #
  #   #   # create a product_price_template if not exist
  #   #   product_price   = CatalogPriceTemplate.find_by_product_nature_id_and_supplier_id_and_assignment_pretax_amount(product_nature.id, coop.id, r.product_unit_price)
  #   #   product_price ||= CatalogPriceTemplate.create!(:currency => "EUR", :assignment_pretax_amount => r.product_unit_price, :product_nature_id => product_nature.id, :tax_id => tax_price_nature_appro.id, :supplier_id => coop.id)
  #   #   # create a purchase_item if not exist
  #   #   # purchase_item   = PurchaseItem.find_by_product_id_and_purchase_id_and_price_id(product.id, purchase.id, product_price.id)
  #   #   # purchase_item ||= PurchaseItem.create!(:quantity => r.quantity, :unit_id => unit_u.id, :price_id => product_price.id, :product_id => product.id, :purchase_id => purchase.id)
  #   #   purchase.items.create!(:quantity => r.quantity, :product_id => product.id)
  #   #   # create an incoming_delivery if status => 2

  #   #   # create an incoming_delivery_item if status => 2


  #   #   print "."
  #   # end
  #   # puts "!"

  # end


  ##############################################################################
  ## UNICOQUE - LOAD HARVEST DATA                                             ##
  ##############################################################################

  # For Unicoque data

  varieties_transcode = {}.with_indifferent_access

  path = loader.path("unicoque", "varieties_transcode.csv")
  if path.exist?
    CSV.foreach(path, headers: true) do |row|
      varieties_transcode[row[0]] = row[1].to_sym
    end
  end


  path = loader.path("unicoque", "recolte.csv")
  if path.exist?

    # create entity corresponding to the cooperative
    cooperative = Entity.find_by_last_name("Unicoque")
    unless cooperative = LegalEntity.where("LOWER(full_name) LIKE ?", "%Unicoque%".mb_chars.downcase).first
        cooperative = LegalEntity.create!(last_name: "Unicoque",
                                       nature: :cooperative,
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

    loader.count :unicoque_harvest do |w|
      CSV.foreach(path, headers: true, col_sep: ";") do |row|
        next if row[0].blank?
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
        sale_price_template_tax = Tax.find_by_reference_name('fr_vat_reduced')
        product_unit_price = (r.total_value_in_euro / r.total_quantity_in_kg).to_f

        catalog.prices.create!(:variant_id => variant.id,
                               :started_at => born_at,
                               :currency => "EUR",
                               :reference_tax_id => sale_price_template_tax.id,
                               :amount => sale_price_template_tax.amount_of(product_unit_price)
                               )

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



end
