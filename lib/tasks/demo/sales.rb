# -*- coding: utf-8 -*-
demo :sales do

  Ekylibre::fixturize :variant_import do |w|
    # Create product_nature for crop plant product
    wheat_crop  = ProductNatureVariant.import_from_nomenclature(:wheat_crop)
    barley_crop = ProductNatureVariant.import_from_nomenclature(:barley_crop)
    corn_crop   = ProductNatureVariant.import_from_nomenclature(:corn_crop)
    durum_wheat_crop = ProductNatureVariant.import_from_nomenclature(:durum_wheat_crop)
    fallow_crop = ProductNatureVariant.import_from_nomenclature(:fallow_crop)
    # @FIXME : find the triticale.
    sunflower_crop = ProductNatureVariant.import_from_nomenclature(:sunflower_crop)
    sorghum_crop   = ProductNatureVariant.import_from_nomenclature(:sorghum_crop)
    temporary_meadow_crop = ProductNatureVariant.import_from_nomenclature(:temporary_meadow_crop)

    # Create product_nature for derivative plant product
    grain  = ProductNatureVariant.import_from_nomenclature(:wheat_grain)
    straw  = ProductNatureVariant.import_from_nomenclature(:wheat_straw)
    hay    = ProductNatureVariant.import_from_nomenclature(:bulk_hay)
    silage = ProductNatureVariant.import_from_nomenclature(:silage)
    grass  = ProductNatureVariant.import_from_nomenclature(:grass)

    # Create product_nature_price for wheat product
    # wheat_price_template   = ProductPriceTemplate.find_by_product_nature_id(wheat.id)
    # wheat_price_template ||= ProductPriceTemplate.create!(:assignment_amount => 211, :currency => "EUR", :assignment_pretax_amount => 200, :product_nature_id => wheat.id, :tax_id => wheat_price_template_tax.id, :listing_id => price_listing.id, :supplier_id => Entity.of_company.id )
    w.check_point
  end

  Ekylibre::fixturize :wheat_sales do |w|
    # Create wheat product
    wheat = ProductNatureVariant.import_from_nomenclature(:wheat_grain)
    catalog = Catalog.first
    wheat_taxes = Tax.all

    responsibles = Person.where(id: User.pluck(:person_id))

    ble = OrganicMatter.find_by_work_number("BLE_2011")
    ble ||= OrganicMatter.create!(:variant_id => wheat.id, :name => "Blé Cap Horn 2011", :identification_number => "BLE_2011_07142011", :work_number => "BLE_2011",
                                :born_at => "2011-07-14", :initial_owner => Entity.of_company) #
    # Sale nature
    sale_nature   = SaleNature.actives.first
    sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => "EUR", :active => true)
    (140 + rand(20)).times do |i|
      # Sale
      d = Date.today - (5*i - rand(4)).days
      sale = Sale.create!(:created_on => d, :client_id => Entity.where(:of_company => false).all.sample.id, :nature_id => sale_nature.id, responsible: responsibles.sample)
      # Sale items
      (rand(5) + 1).times do
        # # find or create a price
        # # @FIXME = waiting for a working method in ProductPrice.price
        # price = ble.price(:amount => rand(150)+25, :tax => wheat_tax)
        price = catalog.prices.find_by(:variant_id => ble.variant_id, :amount => 100.0)
        price ||= catalog.prices.create!(:currency => "EUR",
                                       :amount => 100.00,
                                       :indicator => :population,
                                       :reference_tax_id => wheat_taxes.sample.id,
                                       :variant_id => ble.variant_id
                                       )

        sale.items.create!(:quantity => rand(12.5) + 0.5,
                           :variant_id => wheat.id,
                           :tax_id => wheat_taxes.sample.id,
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
    cow = ProductNatureVariant.find_by(:reference_name => 'calf')
    cow ||= ProductNatureVariant.import_from_nomenclature(:calf)
    catalog = Catalog.first
    cow_price_template_taxes = Tax.all

    animal = Animal.find_by(:work_number => "8926")
    animal ||= Animal.create!(:variant_id => cow.id, :name => "Isere", :identification_number => "1735138926", :work_number => "8926", :born_at => "2013-04-14", :initial_owner => Entity.of_company) #
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
        price = catalog.prices.find_by(:variant_id => animal.variant_id, :amount => 180.00)
        price ||= catalog.prices.create!(:amount => 180.00,
                                       :currency => "EUR",
                                       :indicator => :population,
                                       :reference_tax_id => cow_price_template_taxes.sample.id,
                                       :variant_id => animal.variant_id
                                       )

        sale.items.create!(:quantity => rand(12.5) + 0.5,
                           :variant_id => cow.id,
                           :price_id => price.id,
                           :tax_id => cow_price_template_taxes.sample.id
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
