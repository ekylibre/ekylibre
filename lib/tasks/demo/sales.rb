# -*- coding: utf-8 -*-
demo :sales do

  Ekylibre::fixturize :variant_import do |w|
    # Create product_nature for crop plant product
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
    # wheat_price_template   = ProductPriceTemplate.find_by_product_nature_id(wheat.id)
    # wheat_price_template ||= ProductPriceTemplate.create!(:assignment_amount => 211, :currency => "EUR", :assignment_pretax_amount => 200, :product_nature_id => wheat.id, :tax_id => wheat_price_template_tax.id, :listing_id => price_listing.id, :supplier_id => Entity.of_company.id )
    w.check_point
  end

  Ekylibre::fixturize :wheat_sales do |w|
    # Create wheat product
    wheat = ProductNature.import_from_nomenclature(:wheat_grain).default_variant
    catalog = Catalog.find_by_code("STD")
    wheat_tax = Tax.scoped.first

    ble = OrganicMatter.find_by_work_number("BLE_2011")
    ble ||= OrganicMatter.create!(:variant_id => wheat.id, :name => "Blé Cap Horn 2011", :variety => "organic_matter", :identification_number => "BLE_2011_07142011", :work_number => "BLE_2011",
                                :born_at => "2011-07-14", :owner_id => Entity.of_company.id) #
    # Sale nature
    sale_nature   = SaleNature.actives.first
    sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => "EUR", :active => true)
    (140 + rand(20)).times do |i|
      # Sale
      d = Date.today - (5*i - rand(4)).days
      sale = Sale.create!(:created_on => d, :client_id => Entity.where(:of_company => false).all.sample.id, :nature_id => sale_nature.id)
      # Sale items
      (rand(5) + 1).times do
        # # find or create a price
        # # @FIXME = waiting for a working method in ProductPrice.price
        # price = ble.price(:amount => rand(150)+25, :tax => wheat_tax)
        price = CatalogPrice.find_by_variant_id_and_amount(ble.variant_id, 100.0)
        price ||= CatalogPrice.create!(:currency => "EUR",
                                       :amount => "100.00",
                                       :supplier_id => Entity.of_company.id,
                                       :reference_tax_id => wheat_tax.id,
                                       :variant_id => ble.variant_id
                                       )

        sale.items.create!(:quantity => rand(12.5) + 0.5,
                           :variant_id => wheat.id,
                           :tax_id => wheat_tax.id,
                           :price_id => price.id)
      end
      if !rand(20).zero?
        Sale.where(:id => sale.id).update_all(:created_on => d)
        sale.propose
        if rand(5).zero?
          sale.abort
        elsif !rand(4).zero?
          d += rand(15).days
          sale.confirm(d)
          Sale.where(:id => sale.id).update_all(:confirmed_on => d)
          if !rand(15).zero?
            sale.deliver
            if !rand(25).zero?
              d += rand(5).days
              sale.invoice
              Sale.where(:id => sale.id).update_all(:invoiced_on => d)
            end
          end
        end
      else
        sale.save
      end
      w.check_point
    end
  end

  Ekylibre::fixturize :calf_sales do |w|
    # Create cow product
    cow = ProductNature.find_by(:nomen => 'calf').default_variant
    cow ||= ProductNature.import_from_nomenclature(:calf).default_variant
    catalog = Catalog.find_by_code("STD")
    cow_price_template_tax = Tax.scoped.first

    animal = Animal.find_by(:work_number => "8926")
    animal ||= Animal.create!(:variant_id => cow.id, :name => "Isere", :variety => "bos", :identification_number => "1735138926", :work_number => "8926", :born_at => "2013-04-14", :owner_id => Entity.of_company.id) #
    # Sale nature
    sale_nature   = SaleNature.actives.first
    sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => "EUR", :active => true)
    (140 + rand(20)).times do |i|
      # Sale
      d = Date.today - (5*i - rand(4)).days
      sale = Sale.create!(:created_on => d, :client_id => Entity.where(:of_company => false).all.sample.id, :nature_id => sale_nature.id)
      # Sale items
      (rand(5) + 1).times do
        # # find or create a price
        # # @FIXME = waiting for a working method in ProductPrice.price
        # price = ble.price(:amount => rand(150)+25, :tax => wheat_price_template_tax)
        price = CatalogPrice.find_by(:variant_id => animal.variant_id, :amount => "180.00")
        price ||= CatalogPrice.create!(:amount => "180.00",
                                       :currency => "EUR",
                                       :supplier_id => Entity.of_company.id,
                                       :reference_tax_id => cow_price_template_tax.id,
                                       :variant_id => animal.variant_id
                                       )

        sale.items.create!(:quantity => rand(12.5) + 0.5,
                           :variant_id => cow.id,
                           :price_id => price.id,
                           :tax_id => cow_price_template_tax.id
                           )
      end
      if !rand(20).zero?
        Sale.where(:id => sale.id).update_all(:created_on => d)
        sale.propose
        if rand(5).zero?
          sale.abort
        elsif !rand(4).zero?
          d += rand(15).days
          sale.confirm(d)
          Sale.where(:id => sale.id).update_all(:confirmed_on => d)
          if !rand(15).zero?
            sale.deliver
            if !rand(25).zero?
              d += rand(5).days
              sale.invoice
              Sale.where(:id => sale.id).update_all(:invoiced_on => d)
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
