# -*- coding: utf-8 -*-
task :sales do

  Ekylibre::fixturize :variant_import do |w|
     #Create product_nature for crop plant product
      wheat_crop = ProductNature.import_from_nomenclature(:wheat_crop).default_variant
      barley_crop = ProductNature.import_from_nomenclature(:barley_crop).default_variant
      corn_crop = ProductNature.import_from_nomenclature(:corn_crop).default_variant
      durum_wheat_crop = ProductNature.import_from_nomenclature(:durum_wheat_crop).default_variant
      fallow_crop = ProductNature.import_from_nomenclature(:fallow_crop).default_variant
      # @FIXME : find the triticale.
      sunflower_crop = ProductNature.import_from_nomenclature(:sunflower_crop).default_variant
      sorghum_crop = ProductNature.import_from_nomenclature(:sorghum_crop).default_variant
      temporary_meadow_crop = ProductNature.import_from_nomenclature(:temporary_meadow_crop).default_variant

      # Create product_nature for derivative plant product
      grain = ProductNature.import_from_nomenclature(:grain).default_variant
      straw = ProductNature.import_from_nomenclature(:straw).default_variant
      hay = ProductNature.import_from_nomenclature(:hay).default_variant
      silage = ProductNature.import_from_nomenclature(:silage).default_variant
      grass = ProductNature.import_from_nomenclature(:grass).default_variant

      # Create product_nature_price for wheat product
      #wheat_price_template   = ProductPriceTemplate.find_by_product_nature_id(wheat.id)
      #wheat_price_template ||= ProductPriceTemplate.create!(:assignment_amount => 211, :currency => "EUR", :assignment_pretax_amount => 200, :product_nature_id => wheat.id, :tax_id => wheat_price_template_tax.id, :listing_id => price_listing.id, :supplier_id => Entity.of_company.id )

      # Create wheat product
      wheat = ProductNature.import_from_nomenclature(:wheat_grain).default_variant
      price_listing = ProductPriceListing.find_by_code("STD")
      wheat_price_template_tax = Tax.find_by_amount(5.5)

      ble = OrganicMatter.find_by_work_number("BLE_001")
      ble = OrganicMatter.create!(:variant_id => wheat.id, :name => "Blé Cap Horn 2011", :variety => "organic_matter", :identification_number => "BLE_2011_07142011", :work_number => "BLE_2011",
                                  :born_at => "2011-07-14", :owner_id => Entity.of_company.id) #
  end
  
  Ekylibre::fixturize :sales do |w|
    # Sale nature
      sale_nature   = SaleNature.actives.first
      sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => "EUR", :active => true)
      (140 + rand(20)).times do |i|
        break if i >= max
        # Sale
        d = Date.today - (5*i - rand(4)).days
        sale = Sale.create!(:created_on => d, :client_id => Entity.where(:of_company => false).all.sample.id, :nature_id => sale_nature.id, :sum_method => "wt")
        # Sale items
        (rand(5) + 1).times do
          #find or create a price
          # @FIXME = waiting for a working method in ProductPrice.price
          #price = ble.price(:amount => rand(150)+25, :tax => wheat_price_template_tax)
          price = ProductPrice.find_by_variant_id_and_pretax_amount(ble.variant_id,"100.00")
          price ||= ProductPrice.create!(:pretax_amount => "100.00",
                                         :currency => "EUR",
                                         :amount => "105.50",
                                         :supplier_id => Entity.of_company.id,
                                         :tax_id => wheat_price_template_tax.id,
                                         :variant_id => ble.variant_id
                                         )

          sale.items.create!(:quantity => rand(12.5)+0.5,
                             :product_id => ble.id,
                             :price_id => price.id)
        end
        if !rand(20).zero?
          Sale.update_all({:created_on => d}, {:id => sale.id})
          sale.propose
          if rand(5).zero?
            sale.abort
          elsif !rand(4).zero?
            d += rand(15).days
            sale.confirm(d)
            Sale.update_all({:confirmed_on => d}, {:id => sale.id})
            if !rand(15).zero?
              sale.deliver
              if !rand(25).zero?
                d += rand(5).days
                sale.invoice
                Sale.update_all({:invoiced_on => d}, {:id => sale.id})
              end
            end
          end
        else
          sale.save
        end
        w.check_point
      end
  end
  
end
