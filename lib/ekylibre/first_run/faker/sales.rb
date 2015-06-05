module Ekylibre::FirstRun::Faker

  class Sales < Base

    # Generate all
    def self.generate_sale_cycle(sale, d, options = {})
      factor = options[:factor] || 1
      Sale.where(id: sale.id).update_all(created_at: d)
      return if rand(factor * 20).zero?
      # Propose
      Timecop.travel(d) do
        sale.propose
      end
      # Abort
      if rand(factor * 9).zero?
        d += rand(7).days
        Timecop.travel(d) do
          sale.abort
        end
        return
      end
      # Confirmation
      return if rand(factor * 8).zero?
      d += rand(15).days
      Timecop.travel(d) do
        sale.confirm(d)
        # Sale.where(id: sale.id).update_all(confirmed_at: d)
      end
      # Invoice
      return if rand(factor * 25).zero?
      d += rand(5).days
      Timecop.travel(d) do
        sale.invoice
        # Sale.where(id: sale.id).update_all(invoiced_at: d, payment_at: (d + 30.days))
      end
      # Payment
      return if rand(factor * 4).zero? or sale.amount <= 0
      d += rand(30).days
      Timecop.travel(d) do
        payment = sale.client.incoming_payments.create!(mode: IncomingPaymentMode.all.sample, amount: (sale.amount / (1.0 + rand(3))).to_s.to_f.round(2), to_bank_at: d)
        sale.affair.attach(payment)
      end
      return true
    end

    def self.find_or_create_catalog_item(catalog, variant, amount, d, options = {})
      options[:currency] ||= Preference[:currency]
      options[:amount]  = amount
      options[:variant] = variant
      options[:catalog] = catalog
      unless item = catalog.items.where(variant_id: variant.id).first
        item = catalog.items.create!(options)
      end
      return item
    end

    def run

      self.count :variant_import do |w|
        # Create product_nature for crop plant product
        wheat_crop  = ProductNatureVariant.import_from_nomenclature(:wheat_crop)
        barley_crop = ProductNatureVariant.import_from_nomenclature(:winter_barley_crop)
        corn_crop   = ProductNatureVariant.import_from_nomenclature(:corn_crop)
        durum_wheat_crop = ProductNatureVariant.import_from_nomenclature(:hard_wheat_crop)
        fallow_crop = ProductNatureVariant.import_from_nomenclature(:fallow_crop)
        sunflower_crop = ProductNatureVariant.import_from_nomenclature(:sunflower_crop)
        sorghum_crop   = ProductNatureVariant.import_from_nomenclature(:sorghum_crop)
        temporary_meadow_crop = ProductNatureVariant.import_from_nomenclature(:temporary_meadow_crop)

        # Create product_nature for derivative plant product
        grain  = ProductNatureVariant.import_from_nomenclature(:wheat_grain)
        straw  = ProductNatureVariant.import_from_nomenclature(:bulk_wheat_straw)
        hay    = ProductNatureVariant.import_from_nomenclature(:bulk_hay)
        silage = ProductNatureVariant.import_from_nomenclature(:grass_silage)
        grass  = ProductNatureVariant.import_from_nomenclature(:grass)

        # Create product_nature_price for wheat product
        # wheat_price_template   = ProductPriceTemplate.find_by_product_nature_id(wheat.id)
        # wheat_price_template ||= ProductPriceTemplate.create!(:assignment_amount => 211, :currency => Preference[:currency], :assignment_pretax_amount => 200, :product_nature_id => wheat.id, :tax_id => wheat_price_template_tax.id, :listing_id => price_listing.id, :supplier_id => Entity.of_company.id )
        w.check_point
      end

      self.count :wheat_sales do |w|

        unless cooperative = Organization.where("LOWER(full_name) LIKE ?", "%Kazeni%".mb_chars.downcase).first
          cooperative = Organization.create!(last_name: "Kazeni",
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
        sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => Preference[:currency], :active => true)
        (140 + rand(20)).times do |i|
          # Sale
          d = Time.now - (7*i - rand(4)).days
          sale = Sale.create!(:created_at => d, :client_id => cooperative.id, :nature_id => sale_nature.id, responsible: responsibles.sample)
          # Sale items
          (rand(5) + 1).times do
            catalog_item = self.class.find_or_create_catalog_item(catalog, wheat, rand(60) + 180, d, reference_tax: wheat_taxes.sample)
            sale.items.create!(quantity: rand(12.5) + 0.5, tax: wheat_taxes.sample, unit_pretax_amount: catalog_item.amount, variant: catalog_item.variant)
          end
          self.class.generate_sale_cycle(sale, d)
          w.check_point
        end
      end

      self.count :calf_sales do |w|

        unless cooperative = Organization.where("LOWER(full_name) LIKE ?", "%Caroli%".mb_chars.downcase).first
          cooperative = Organization.create!(last_name: "Caroli",
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
        cow_catalog_item_template_taxes = Tax.all

        # Sale nature
        sale_nature   = SaleNature.actives.first
        sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => Preference[:currency], :active => true)
        (140 + rand(20)).times do |i|
          # Sale
          d = Time.now - (7*i - rand(4)).days
          sale = Sale.create!(:created_at => d, :client_id => cooperative.id, :nature_id => sale_nature.id)
          # Sale items
          (rand(5) + 1).times do
            catalog_item = self.class.find_or_create_catalog_item(catalog, cow, rand(40) + 140, d, reference_tax: cow_catalog_item_template_taxes.sample)
            sale.items.create!(quantity: rand(4) + 1, unit_pretax_amount: catalog_item.amount, variant: catalog_item.variant, tax: cow_catalog_item_template_taxes.sample)
          end
          self.class.generate_sale_cycle(sale, d)
          w.check_point
        end
      end

      self.count :milk_sales do |w|

        unless cooperative = Organization.where("LOWER(full_name) LIKE ?", "%TerriLacti%".mb_chars.downcase).first
          cooperative = Organization.create!(last_name: "TerriLacti",
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
        milk = ProductNatureVariant.import_from_nomenclature(:cow_milk)
        catalog = Catalog.find_by(:usage => 'sale')
        milk_catalog_item_template_tax = Tax.find_by(:reference_name => 'french_vat_reduced')

        sale_nature   = SaleNature.actives.first
        sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => Preference[:currency], :active => true)
        120.times do |i|
          # Sale
          d = Time.now - i.months
          sale = Sale.create!(created_at: d, client: cooperative, nature: sale_nature)
          # Sale items
          catalog_item = self.class.find_or_create_catalog_item(catalog, milk, rand(0.04)+0.300, d, reference_tax: milk_catalog_item_template_tax)
          sale.items.create!(quantity: rand(5000) + 30000, unit_pretax_amount: catalog_item.amount, variant: catalog_item.variant, tax: milk_catalog_item_template_tax)
          self.class.generate_sale_cycle(sale, d)
          w.check_point
        end
      end


      self.count :bottle_wine_sales do |w|

        unless cooperative = Organization.where("LOWER(full_name) LIKE ?", "%Vitis%".mb_chars.downcase).first
          cooperative = Organization.create!(last_name: "Vitis",
                                            nature: :cooperative,
                                            vat_number: "FR00123456789",
                                            supplier: true, client: true,
                                            mails_attributes: {
                                              0 => {
                                                canal: "mail",
                                                mail_line_4: "145 rue du port",
                                                mail_line_6: "17300 JONZAC",
                                                mail_country: :fr
                                              }
                                            },
                                            emails_attributes: {
                                              0 => {
                                                canal: "email",
                                                coordinate: "contact@vitis.coop"
                                              }
                                            })
        end

        # Create wheat product
        wine = ProductNatureVariant.import_from_nomenclature(:bottle_75cl_wine)
        catalog = Catalog.first
        wine_taxes = Tax.all

        responsibles = Person.where(id: User.pluck(:person_id))

        # Sale nature
        sale_nature   = SaleNature.actives.first
        sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => Preference[:currency], :active => true)
        (140 + rand(20)).times do |i|
          # Sale
          d = Time.now - (7*i - rand(4)).days
          sale = Sale.create!(:created_at => d, :client_id => cooperative.id, :nature_id => sale_nature.id, responsible: responsibles.sample)
          # Sale items
          (rand(5) + 1).times do
            catalog_item = self.class.find_or_create_catalog_item(catalog, wine, rand(2.8) + 8, d, reference_tax: wine_taxes.sample)
            sale.items.create!(quantity: rand(120) + 60, tax: wine_taxes.sample, unit_pretax_amount: catalog_item.amount, variant: catalog_item.variant)
          end
          self.class.generate_sale_cycle(sale, d)
          w.check_point
        end
      end

      self.count :bulk_wine_sales do |w|

        unless cooperative = Organization.where("LOWER(full_name) LIKE ?", "%Vitis%".mb_chars.downcase).first
          cooperative = Organization.create!(last_name: "Vitis",
                                            nature: :cooperative,
                                            vat_number: "FR00123456789",
                                            supplier: true, client: true,
                                            mails_attributes: {
                                              0 => {
                                                canal: "mail",
                                                mail_line_4: "145 rue du port",
                                                mail_line_6: "17300 JONZAC",
                                                mail_country: :fr
                                              }
                                            },
                                            emails_attributes: {
                                              0 => {
                                                canal: "email",
                                                coordinate: "contact@vitis.coop"
                                              }
                                            })
        end

        # Create wheat product
        wine = ProductNatureVariant.import_from_nomenclature(:wine)
        catalog = Catalog.first
        wine_taxes = Tax.all

        responsibles = Person.where(id: User.pluck(:person_id))

        # Sale nature
        sale_nature   = SaleNature.actives.first
        sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => Preference[:currency], :active => true)
        (2 + rand(2)).times do |i|
          # Sale
          d = Time.now - (7*i - rand(4)).days
          sale = Sale.create!(:created_at => d, :client_id => cooperative.id, :nature_id => sale_nature.id, responsible: responsibles.sample)
          # Sale items
          (rand(5) + 1).times do
            # # find or create a catalog_item
            # # @FIXME = waiting for a working method in ProductCatalog_Item.catalog_item
            # catalog_item = ble.catalog_item(:amount => rand(150)+25, :tax => wheat_tax)
            catalog_item = catalog.items.find_by(variant_id: wine.id)
            catalog_item ||= catalog.items.create!(:currency => Preference[:currency],
                                                   :amount => rand(130) + 850,
                                                   :reference_tax => wine_taxes.sample,
                                                   :variant_id => wine.id
                                                  )

            sale.items.create!(:quantity => rand(25) + 10,
                               :tax => wine_taxes.sample, unit_pretax_amount: catalog_item.amount, variant: catalog_item.variant)
          end
          self.class.generate_sale_cycle(sale, d)
          w.check_point
        end
      end
    end

  end
end
