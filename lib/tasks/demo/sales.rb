# -*- coding: utf-8 -*-
demo :sales do

  Ekylibre::fixturize :variant_import do |w|
    # Create product_nature for crop plant product
    wheat_crop  = ProductNatureVariant.import_from_nomenclature(:wheat_crop)
    barley_crop = ProductNatureVariant.import_from_nomenclature(:winter_barley_crop)
    corn_crop   = ProductNatureVariant.import_from_nomenclature(:corn_crop)
    durum_wheat_crop = ProductNatureVariant.import_from_nomenclature(:hard_wheat_crop)
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

    unless cooperative = LegalEntity.where("LOWER(full_name) LIKE ?", "%Kazeni%".mb_chars.downcase).first
      cooperative = LegalEntity.create!(last_name: "Kazeni",
                                        nature: :cooperative,
                                        vat_number: "FR00123456789",
                                        supplier: true, client: true,
                                        mails_attributes: {
                                          0 => {
                                            canal: "mail",
                                            mail_line_4: "145 rue du port",
                                            mail_line_6: "17000 LAROCHELLE",
                                            mail_country: :fr
                                          }
                                        },
                                        emails_attributes: {
                                          0 => {
                                            canal: "email",
                                            coordinate: "contact@kazeni.coop"
                                          }
                                        })
    end

    # Create wheat product
    wheat = ProductNatureVariant.import_from_nomenclature(:wheat_grain)
    catalog = Catalog.first
    wheat_taxes = Tax.all

    responsibles = Person.where(id: User.pluck(:person_id))

    # Sale nature
    sale_nature   = SaleNature.actives.first
    sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => "EUR", :active => true)
    (140 + rand(20)).times do |i|
      # Sale
      d = Date.today - (5*i - rand(4)).days
      sale = Sale.create!(:created_on => d, :client_id => cooperative.id, :nature_id => sale_nature.id, responsible: responsibles.sample)
      # Sale items
      (rand(5) + 1).times do
        # # find or create a price
        # # @FIXME = waiting for a working method in ProductPrice.price
        # price = ble.price(:amount => rand(150)+25, :tax => wheat_tax)
        price = catalog.prices.find_by(:variant_id => wheat.id, :amount => 100.0)
        price ||= catalog.prices.create!(:currency => "EUR",
                                       :started_at => d.to_time,
                                       :amount => rand(60) + 180,
                                       :indicator_name => :population,
                                       :reference_tax_id => wheat_taxes.sample.id,
                                       :variant_id => wheat.id
                                       )

        sale.items.create!(:quantity => rand(12.5) + 0.5,
                           :tax_id => wheat_taxes.sample.id,
                           :price => price)
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

    unless cooperative = LegalEntity.where("LOWER(full_name) LIKE ?", "%Caroli%".mb_chars.downcase).first
      cooperative = LegalEntity.create!(last_name: "Caroli",
                                        nature: :cooperative,
                                        vat_number: "FR00123456789",
                                        supplier: true, client: true,
                                        mails_attributes: {
                                          0 => {
                                            canal: "mail",
                                            mail_line_4: "145 rue du port",
                                            mail_line_6: "16000 ANGOULEME",
                                            mail_country: :fr
                                          }
                                        },
                                        emails_attributes: {
                                          0 => {
                                            canal: "email",
                                            coordinate: "contact@caroli.coop"
                                          }
                                        })
    end

    # Create cow product
    cow = ProductNatureVariant.find_by(:reference_name => 'calf')
    cow ||= ProductNatureVariant.import_from_nomenclature(:calf)
    catalog = Catalog.first
    cow_price_template_taxes = Tax.all

    # Sale nature
    sale_nature   = SaleNature.actives.first
    sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => "EUR", :active => true)
    (140 + rand(20)).times do |i|
      # Sale
      d = Date.today - (5*i - rand(4)).days
      sale = Sale.create!(:created_on => d, :client_id => cooperative.id, :nature_id => sale_nature.id)
      # Sale items
      (rand(5) + 1).times do
        # # find or create a price
        # # @FIXME = waiting for a working method in ProductPrice.price
        # price = ble.price(:amount => rand(150)+25, :tax => wheat_price_template_tax)
        price = catalog.prices.find_by(:variant_id => cow.id, :amount => 180.00)
        price ||= catalog.prices.create!(:amount => rand(40) + 140,
                                       :started_at => d.to_time,
                                       :currency => "EUR",
                                       :indicator_name => :population,
                                       :reference_tax_id => cow_price_template_taxes.sample.id,
                                       :variant_id => cow.id
                                       )

        sale.items.create!(:quantity => rand(4) + 1,
                           :price => price,
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

  Ekylibre::fixturize :milk_sales do |w|

    unless cooperative = LegalEntity.where("LOWER(full_name) LIKE ?", "%TerriLacti%".mb_chars.downcase).first
      cooperative = LegalEntity.create!(last_name: "TerriLacti",
                                        nature: :cooperative,
                                        vat_number: "FR00123456789",
                                        supplier: true, client: true,
                                        mails_attributes: {
                                          0 => {
                                            canal: "mail",
                                            mail_line_4: "145 rue du port",
                                            mail_line_6: "17000 SURGERES",
                                            mail_country: :fr
                                          }
                                        },
                                        emails_attributes: {
                                          0 => {
                                            canal: "email",
                                            coordinate: "contact@terrilacti.coop"
                                          }
                                        })
    end
    # Create milk product
    milk = ProductNatureVariant.find_by(:reference_name => 'cow_milk')
    milk ||= ProductNatureVariant.import_from_nomenclature(:cow_milk)
    catalog = Catalog.find_by(:usage => 'sale')
    milk_price_template_taxes = Tax.find_by(:amount => '5.0000')

    sale_nature   = SaleNature.actives.first
    sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => "EUR", :active => true)
    period = [0,1,2,3,4,5,6,7,8,9,10,11]
    period.each do |i|
      # Sale
      d = Date.today - i.months
      sale = Sale.create!(:created_on => d, :client_id => cooperative.id, :nature_id => sale_nature.id)
      # Sale items
        price = catalog.prices.find_by(:variant_id => milk.id, :amount => rand(0.04)+0.340)
        price ||= catalog.prices.create!(:amount => rand(0.04)+0.340,
                                       :started_at => d.to_time,
                                       :currency => "EUR",
                                       :indicator_name => :population,
                                       :reference_tax_id => milk_price_template_taxes.id,
                                       :variant_id => milk.id
                                       )

        sale.items.create!(:quantity => rand(5000) + 30000,
                           :price => price,
                           :tax_id => milk_price_template_taxes.id
                           )

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
