# -*- coding: utf-8 -*-

require 'ostruct'

namespace :db do
  desc "Build demo data"
  task :demo => :environment do
    start = Time.now
    STDOUT.sync = true
    max = ENV["max"].to_i
    max = 1_000_000 if max.zero?
    puts "Started: "
    ActiveRecord::Base.transaction do
      #############################################################################
      # Import accountancy
      file = Rails.root.join("test", "fixtures", "files", "general_ledger-istea.txt")
      picture_undefined = Rails.root.join("test", "fixtures", "files", "portrait-undefined.png")
      journals = {
        "2" => "BILAN DEBUT",
        "8" => "BILAN CLOTURE",
        "11" => "CAISSE 1",
        "21" => "CRCA",
        "22" => "BANQUE 2",
        "30" => "STOCKS DEBUT COMPTABLE",
        "31" => "STOCKS FIN COMPTABLE",
        "32" => "STOCK DEBUT ECO",
        "33" => "STOCK FIN ECO EXT N+1",
        "35" => "OPER ECO EXERC N",
        "41" => "C-C-POSTAUX",
        "50" => "OISE FORCE",
        "51" => "SAINTE-ANNE MORTE SAISON",
        "60" => "ACHATS FOURNIS COLLECT",
        "70" => "VENTES CLIENTS COLLECTIF",
        "79" => "VENTES CLIENTS GEST COMM",
        "82" => "DEDUCT/REINT EXTRA-COMPT",
        "83" => "REAJUST. FICHE GESTION",
        "84" => "REFERENCES N-1",
        "90" => "OPERATION DIVERSES",
        "91" => "O.D. CENTRALISAT. TVA",
        "92" => "OPER ASSEMBLEE GENERALE",
        "93" => "OPER FIN EX EXT N+1",
        "95" => "OPER. FIN EXERCICE",
        "96" => "DETTES FIN EXER 401",
        "97" => "CREANCES FIN EXER. 411",
        "98" => "DETTES PROVISIONNEES",
        "101" => "CORRECTIF FISCAL (COUT)",
        "102" => "CORRECTIF ECO (COUT)",
        "103" => "CORRECT FISC (COUT) TERRE",
        "104" => "CORRECT ECO (COUT) TERRE",
        "105" => "COUT FISC CULT N-1 TERRE",
        "106" => "COUT ECO CULT N-1 TERRE"
      }

      fy = FinancialYear.first
      fy.started_on = Date.civil(2007, 1, 1)
      fy.stopped_on = Date.civil(2007, 12, 31)
      fy.code = "EX2007"
      fy.save!
      en_org = "legal_entity"

      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] General ledger: "
      CSV.foreach(file, :encoding => "CP1252", :col_sep => ";") do |row|
        jname = (journals[row[1]] || row[1]).capitalize
        r = OpenStruct.new(:account => Account.get(row[0]),
                           :journal => Journal.find_by_name(jname) || Journal.create!(:name => jname, :code => row[1]),
                           :page_number => row[2], # What's that ?
                           :printed_on => Date.civil(*row[3].split(/\-/).map(&:to_i)),
                           :entry_number => row[4].to_s.strip.upcase.to_s.gsub(/[^A-Z0-9]/, ''),
                           :entity_name => row[5],
                           :entry_name => row[6],
                           :debit => row[7].to_d,
                           :credit => row[8].to_d,
                           :vat => row[9],
                           :comment => row[10],
                           :letter => row[11],
                           :what_on => row[12])


        fy = FinancialYear.at(r.printed_on)
        unless entry = JournalEntry.find_by_journal_id_and_number(r.journal.id, r.entry_number)
          number = r.entry_number
          number = r.journal.code + rand(10000000000).to_s(36) if number.blank?
          entry = r.journal.entries.create!(:printed_on => r.printed_on, :number => number.upcase)
        end
        column = (r.debit.zero? ? :credit : :debit)
        entry.send("add_#{column}", r.entry_name, r.account, r.send(column))
        if r.account.number.match(/^401/)
          unless Entity.find_by_origin(r.entity_name)
            f = File.open(picture_undefined)
            entity = LegalEntity.create!(:last_name => r.entity_name.mb_chars.capitalize, :nature => en_org, :supplier => true, :supplier_account_id => r.account_id, :picture => f, :origin => r.entity_name)
            f.close
            entity.addresses.create!(:canal => :email, :coordinate => ["contact", "info", r.entity_name.parameterize].sample + "@" + r.entity_name.parameterize + "." + ["fr", "com", "org", "eu"].sample)
            entity.addresses.create!(:canal => :phone, :coordinate => "+33" + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s)
          end
        end
        if r.account.number.match(/^411/)
          unless Entity.find_by_origin(r.entity_name)
            f = File.open(picture_undefined)
            entity = LegalEntity.create!(:last_name => r.entity_name.mb_chars.capitalize, :nature => en_org, :client => true, :client_account_id => r.account_id, :picture => f, :origin => r.entity_name)
            f.close
            entity.addresses.create!(:canal => :email, :coordinate => ["contact", "info", r.entity_name.parameterize].sample + "@" + r.entity_name.parameterize + "." + ["fr", "com", "org", "eu"].sample)
            entity.addresses.create!(:canal => :phone, :coordinate => "+33" + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s)
          end
        end

        print "."
        break if Entity.count >= max
      end

      mails = [
               {:mail_line_4 => "712 rue de la Mairie", :mail_line_6 => "47290 Cancon"},
               {:mail_line_4 => "55 Rue du Faubourg Saint-Honoré", :mail_line_6 => "75008 Paris"},
               {:mail_line_4 => "Le Bourg", :mail_line_6 => "47210 Saint-Eutrope-de-Born"},
               {:mail_line_4 => "Avenue de la Libération", :mail_line_6 => "47150 Monflanquin"},
               {:mail_line_4 => "Rue du port", :mail_line_6 => "47440 Casseneuil"},
               {:mail_line_4 => "Avenue René Cassin", :mail_line_6 => "47110 Sainte-Livrade-sur-Lot"},
              ]

      Entity.find_each do |entity|
        entity.addresses.create!(mails.sample.merge(:canal => :mail))
      end
      puts "!"

      #############################################################################
      # Import synel
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Synel: "
      # h = ProductVariety.find_by_code("cattle")
      # p = ProductVariety.find_by_code("animal")
      # h ||= ProductVariety.create!(:name => "Bovin", :code => "cattle", :product_type => "Animal", :parent_id => (p ? p.id : nil))
      # v = ProductVariety.find_by_code("normande")
      # v ||= ProductVariety.create!(:name => "Normande", :code => "normande", :product_type => "Animal", :parent_id => (h ? h.id : nil))
      cow_unit = "head"
      cow_product_account = Account.find_in_chart(:adult_animal_product)
      cow_stock_account = Account.find_in_chart(:long_time_animal_stock)
      # add default variety for building
      # b = ProductVariety.find_by_code("animal_house")
      # q = ProductVariety.find_by_code("building")
      # b ||= ProductVariety.create!(:name => "Bâtiments Animaux", :code => "animal_house", :product_type => "Building", :parent_id => (q ? q.id : nil))
      # add default category for all
      category = ProductNatureCategory.first
      category ||= ProductNatureCategory.create!(:name => "Défaut")
      # create default product_nature to create animal
      cow = ProductNature.find_by_number("CATTLE")
      cow ||= ProductNature.create!(:name => "adult_cow", :number => "CATTLE", :storable => true, :stock_account_id => cow_stock_account.id, :saleable => true, :product_account_id => cow_product_account.id, :variety => "bos", :unit => cow_unit, :category_id => category.id)
      # create default product_nature_indicator for cow (like in XML nomenclature)
      for a in ["weight", "animal_life_state", "mammalia_reproduction_event_abortion", "mammalia_reproduction_method_embryo_transplant", "mammalia_born_cycle", "mammalia_reproduction_state", "mammalia_twins_condition", "mammalia_lactation_state", "animal_disease_state"]
        product_nature_indicator = ProductNatureIndicator.where(:nature => a, :product_nature_id => cow.id ).first
        product_nature_indicator ||= ProductNatureIndicator.create!(:product_nature_id => cow.id, :nature => a)
      end

      # add default groups for animal
      group1 = AnimalGroup.find_by_name("VL")
      group1 ||= AnimalGroup.create!(:name => "VL", :active => true, :external => false, :reproductor => false, :reservoir => false, :description => "Vache Laitière", :nature_id => cow.id, :unit => cow_unit, :variety => "bos", :owner_id => Entity.of_company.id, :number => "VL")
      group2 = AnimalGroup.find_by_name("GEN")
      group2 ||= AnimalGroup.create!(:name => "GEN", :active => true, :external => false, :reproductor => false, :reservoir => false, :description => "Génisses", :nature_id => cow.id, :unit => cow_unit, :variety => "bos", :owner_id => Entity.of_company.id, :number => "GEN")
      group3 = AnimalGroup.find_by_name("VEAU")
      group3 ||= AnimalGroup.create!(:name => "VEAU", :active => true, :external => false, :reproductor => false, :reservoir => false, :description => "Veaux", :nature_id => cow.id, :unit => cow_unit, :variety => "bos", :owner_id => Entity.of_company.id, :number => "VEAU")
      group4 = AnimalGroup.find_by_name("TAURILLON")
      group4 ||= AnimalGroup.create!(:name => "TAURILLON", :active => true, :external => false, :reproductor => false, :reservoir => false, :description => "Taurillons", :nature_id => cow.id, :unit => cow_unit, :variety => "bos", :owner_id => Entity.of_company.id, :number => "TAURILLON")
      # create default product_nature to place animal
      place_nature = ProductNature.find_by_number("CATTLE_HOUSE")
      place_nature ||= ProductNature.create!(:name => "Stabulation", :number => "CATTLE_HOUSE", :variety => "building", :unit => "unity", :category_id => category.id)

      # create default product to place animal
      place = Building.find_by_work_number("STABU_01")
      place ||= Building.create!(:name => "Stabulation principale", :identification_number => "S0001", :work_number => "STABU_01", :born_at => Time.now, :reservoir => true, :unit => "unity", :content_nature_id => cow.id, :variety => "building", :nature_id => place_nature.id, :owner_id => Entity.of_company.id, :number => "STABU_01")

      arrival_causes = {"N" => :birth, "A" => :purchase, "P" => :housing, "" => :other }
      departure_causes = {"M" => :death, "B" => :sale, "" => :other, "C" => :consumption , "E" => :sale}


      file = Rails.root.join("test", "fixtures", "files", "animals-synel17.csv")
      pictures = Dir.glob(Rails.root.join("test", "fixtures", "files", "animals-ld", "*.jpg"))
      CSV.foreach(file, :encoding => "CP1252", :col_sep => ";", :headers => true) do |row|
        next if row[4].blank?
        r = OpenStruct.new(:country => row[0],
                           :identification_number => row[1],
                           :work_number => row[2],
                           :name => (row[3].blank? ? Faker::Name.first_name : row[3].capitalize),
                           :born_on => (row[4].blank? ? nil : Date.civil(*row[4].to_s.split(/\//).reverse.map(&:to_i))),
                           :corabo => row[5],
                           :sex => (row[6] == "F" ? :female : :male),
                           :arrival_cause => (arrival_causes[row[7]] || row[7]),
                           :arrived_on => (row[8].blank? ? nil : Date.civil(*row[8].to_s.split(/\//).reverse.map(&:to_i))),
                           :departure_cause => (departure_causes[row[9]] ||row[9]),
                           :departed_on => (row[10].blank? ? nil : Date.civil(*row[10].to_s.split(/\//).reverse.map(&:to_i)))
                           )
        f = File.open(pictures.sample)
        animal = Animal.create!(:name => r.name, :unit => cow_unit, :variety => "bos", :identification_number => r.identification_number, :work_number => r.work_number, :born_at => r.born_on, :sex => r.sex, :picture => f, :nature_id => cow.id, :owner_id => Entity.of_company.id, :reproductor => (r.sex == :male ? rand(2).zero? : false), :number => r.work_number)
        f.close
        # set default indicators
        animal.indicator_data.create!(:indicator => "weight", :value => "689.50" ,:measure_unit => "kilogram" ,:measured_at => Time.now )
        animal.indicator_data.create!(:indicator => "weight", :value => "589.50" ,:measure_unit => "kilogram" ,:measured_at => (Time.now - 6.months) )
        animal.indicator_data.create!(:indicator => "weight", :value => "479.50" ,:measure_unit => "kilogram" ,:measured_at => (Time.now - 1.year) )
        animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "healthy" ,:measured_at => Time.now )
        animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "sick" ,:measured_at => (Time.now - 2.days) )
        animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "healthy" ,:measured_at => (Time.now - 3.days) )
        # place the current animal in the default place (stabulation) with dates
        ProductLocalization.create!(:container_id => place.id, :product_id => animal.id, :nature => :interior, :started_at => r.arrived_on, :stopped_at => r.departed_on, :arrival_cause => r.arrival_cause, :departure_cause => r.departure_cause)
        # place the current animal in the default group with dates
        # @TODO set correct group if sex M / F and age > 2 year
        # group1 if sex = female and age > 3 years
        # group2 if sex = female and age between 1 and 3 years
        # group3 if  age < 3 month
        # group4 if sex = male and age > 1 years
        ProductMembership.create!(:member_id => animal.id, :group_id => group1.id, :started_at => r.arrived_on, :stopped_at => r.departed_on )
        print "."
        break if Animal.count >= max
      end

      # Assign parents
      Animal.where(:nature_id => cow.id).find_each do |animal|
        animal.father = Animal.fathers.where("born_at <= ?", (animal.born_at - 45.months)).to_a.sample rescue nil
        animal.mother = Animal.mothers.where("born_at <= ?", (animal.born_at - 36.months)).to_a.sample rescue nil
        animal.save!
      end
      puts "!"


      #############################################################################
      # Import shapefile
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Shapefile (from TelePAC 2013): "
      # v = ProductVariety.find_by_code("land_parcel")
      # p = ProductVariety.find_by_code("place")
      # v ||= ProductVariety.create!(:name => "Parcelle", :code => "land_parcel", :product_type => "LandParcel", :parent_id => (p ? p.id : nil))
      land_unit = "square_meter"
      category = ProductNatureCategory.first
      category ||= ProductNatureCategory.create!(:name => "Défaut")
      land_parcel = ProductNature.find_by_number("LANDPARCEL")
      land_parcel ||= ProductNature.create!(:name => "Parcelle", :number => "LANDPARCEL", :variety => "land_parcel", :unit => land_unit, :category_id => category.id)
      RGeo::Shapefile::Reader.open(Rails.root.join("test", "fixtures", "files", "ilot_017005218.shp").to_s, :srid => 2154) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          LandParcel.create!(:shape => record.geometry, :name => Faker::Name.first_name, :variety => "land_parcel", :unit => land_unit, :born_at => Date.civil(2000, 1, 1), :nature_id => land_parcel.id, :owner_id => Entity.of_company.id, :identification_number => record.attributes['PACAGE'].to_s + record.attributes['CAMPAGNE'].to_s + record.attributes['NUMERO'].to_s)
          # puts "Record number #{record.index}:"
          # puts "  Geometry: #{record.geometry.as_text}"
          # puts "  Attributes: #{record.attributes.inspect}"
          print "."
        end
      end
      puts "!"


      #############################################################################
      # Create variety for wheat product
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Sale: "
      price_listing = ProductPriceListing.find_by_code("PARDEFAU")
      wheat_category ||= ProductNatureCategory.create!(:name => "Produits régionaux")
      # b = ProductVariety.find_by_code("matter")
      # b ||= ProductVariety.create!(:name => "Matière vegetale", :code => "matter", :product_type => "Plant", :parent_id => (b ? b.id : nil))
      # c = ProductVariety.find_by_code("caphorn")
      # c ||= ProductVariety.create!(:name => "CAPHORN", :code => "caphorn", :product_type => "Plant", :parent_id => (b ? b.id : nil))
      wheat_unit = "ton"
      # Create product_nature for wheat product
      wheat_charge_account = Account.find_by_number("601")
      wheat_product_account = Account.find_by_number("701")
      wheat_stock_account = Account.find_in_chart(:plant_derivative_stock)
      wheat = ProductNature.find_by_number("BLE")
      wheat ||= ProductNature.create!(:charge_account_id => wheat_charge_account.id, :product_account_id => wheat_product_account.id, :stock_account_id => wheat_stock_account.id, :name => "Blé", :number => "BLE", :saleable => true, :purchasable => true, :active => true, :storable => true, :variety => "plant", :derivative => "grains", :unit => wheat_unit, :category_id => wheat_category.id)
      wheat_price_template_tax = Tax.find_by_amount(5.5)
      # Create product_nature_price for wheat product
      wheat_price_template   = ProductPriceTemplate.find_by_product_nature_id(wheat.id)
      wheat_price_template ||= ProductPriceTemplate.create!(:assignment_amount => 211, :currency => "EUR", :assignment_pretax_amount => 200, :product_nature_id => wheat.id, :tax_id => wheat_price_template_tax.id, :listing_id => price_listing.id, :supplier_id => Entity.of_company.id )
      # Create wheat product
      ble = Plant.find_by_work_number("BLE_001")
      ble = Plant.create!(:name => "Blé Cap Horn 2011", :variety => "plant", :unit => wheat_unit, :identification_number => "BLE_2011_07142011", :work_number => "BLE_2011", :born_at => "2011-07-14", :nature_id => wheat.id, :owner_id => Entity.of_company.id, :number => "BLE_2011") #

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
          sale.items.create!(:quantity => rand(12.5)+0.5, :product_id => ble.id)
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
        print "."
      end

      puts "!"


      #############################################################################
      # import Coop Order to make automatic purchase
      # @TODO finish with two level (purchases and purchases_lines)
      #
      # set the coop
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Coop Purchases: "
      suppliers = Entity.where(:of_company => false, :supplier => true).reorder(:supplier_account_id, :last_name) # .where(" IS NOT NULL")
      coop = suppliers.offset((suppliers.count/2).floor).first

      # add a Coop purchase_nature
      purchase_nature   = PurchaseNature.actives.first
      purchase_nature ||= PurchaseNature.create!(:name => I18n.t('models.purchase_nature.default.name'), :currency => "EUR", :active => true)
      # Asset Code
      charge_account_nature_coop = Account.find_by_number("6021")
      stock_account_nature_coop = Account.find_by_number("321")
      # status to map
      status = {
        "Liquidé" => :order,
        "A livrer" => :estimate,
        "Supprimé" => :aborted
      }

      file = Rails.root.join("test", "fixtures", "files", "coop-appro.csv")
      CSV.foreach(file, :encoding => "UTF-8", :col_sep => ";", :headers => true) do |row|
        r = OpenStruct.new(:order_number => row[0],
                           :ordered_on => Date.civil(*row[1].to_s.split(/\//).reverse.map(&:to_i)),
                           :product_nature_category => ProductNatureCategory.find_by_name(row[2]) || ProductNatureCategory.create!(:catalog_name => row[2], :name => row[2], :published => true ) ,
                           :product_nature_name => row[3],
                           :matter_name => row[4],
                           :quantity => row[5].to_d,
                           :product_deliver_quantity => row[6].to_d,
                           :product_unit_price => row[7].to_d,
                           :order_status => (status[row[8]] || :draft)
                           )
        # create a purchase if not exist
        purchase   = Purchase.find_by_reference_number(r.order_number)
        purchase ||= Purchase.create!(:state => r.order_status, :currency => "EUR", :nature_id => purchase_nature.id, :reference_number => r.order_number, :supplier_id => coop.id, :planned_on => r.ordered_on, :created_on => r.ordered_on)
        tax_price_nature_appro = Tax.find_by_amount(19.6)
        # create a product_nature if not exist
        product_nature   = ProductNature.find_by_name(r.product_nature_name)
        product_nature ||= ProductNature.create!(:stock_account_id => stock_account_nature_coop.id, :charge_account_id => charge_account_nature_coop.id, :name => r.product_nature_name, :number => r.product_nature_name, :saleable => false, :purchasable => true, :active => true, :storable => true, :variety => "building", :unit => "unity", :category_id => r.product_nature_category.id)
        # create a product (Matter) if not exist
        product   = Matter.find_by_name(r.matter_name)
        product ||= Matter.create!(:name => r.matter_name, :identification_number => r.matter_name, :work_number => r.matter_name, :born_at => Time.now, :nature_id => product_nature.id, :owner_id => Entity.of_company.id, :number => r.matter_name) #
        # create a product_price_template if not exist
        product_price   = ProductPriceTemplate.find_by_product_nature_id_and_supplier_id_and_assignment_pretax_amount(product_nature.id, coop.id, r.product_unit_price)
        product_price ||= ProductPriceTemplate.create!(:currency => "EUR", :assignment_pretax_amount => r.product_unit_price, :product_nature_id => product_nature.id, :tax_id => tax_price_nature_appro.id, :supplier_id => coop.id)
        # create a purchase_item if not exist
        # purchase_item   = PurchaseItem.find_by_product_id_and_purchase_id_and_price_id(product.id, purchase.id, product_price.id)
        # purchase_item ||= PurchaseItem.create!(:quantity => r.quantity, :unit_id => unit_u.id, :price_id => product_price.id, :product_id => product.id, :purchase_id => purchase.id)
        # puts "Default PPT: " + ProductPriceTemplate.by_default.class.name # (coop.id, product.nature_id).inspect
        purchase.items.create!(:quantity => r.quantity, :product_id => product.id) unless r.quantity.zero?
        # create an incoming_delivery if status => 2

        # create an incoming_delivery_item if status => 2


        print "."
      end
      puts "!"

      # #############################################################################
      # # import Coop Deliveries to make automatic sales
      # # @TODO finish with two level (sales and sales_lines)
      # # set the coop
      # print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Coop Sales: "
      # clients = Entity.where(:of_company => false).reorder(:client_account_id, :last_name) # .where(" IS NOT NULL")
      # coop = clients.offset((clients.count/2).floor).first
      # unit_u = Unit.get(:u)
      # # add a Coop sale_nature
      # sale_nature   = SaleNature.actives.first
      # sale_nature ||= SaleNature.create!(:name => I18n.t('models.sale_nature.default.name'), :currency => "EUR", :active => true)
      # # Asset Code
      # sale_account_nature_coop = Account.find_by_number("701")
      # stock_account_nature_coop = Account.find_by_number("321")

      # file = Rails.root.join("test", "fixtures", "files", "coop-apport.csv")
      # CSV.foreach(file, :encoding => "UTF-8", :col_sep => ";", :headers => false, :quote_char => "'") do |row|
      #   r = OpenStruct.new(:delivery_number => row[0],
      #                      :delivered_on => Date.civil(*row[1].to_s.split(/\//).reverse.map(&:to_i)),
      #                      :delivery_place => row[2],
      #                      :product_nature_name => row[3],
      #                      :product_net_weight => row[4].to_d,
      #                      :product_standard_weight => row[5].to_d,
      #                      :product_humidity => row[6].to_d,
      #                      :product_impurity => row[7].to_d,
      #                      :product_specific_weight => row[8].to_d,
      #                      :product_proteins => row[9].to_d,
      #                      :product_cal => row[10].to_d,
      #                      :product_mad => row[11].to_d,
      #                      :product_grade => row[12].to_d,
      #                      :product_expansion => row[13].to_d
      #                      )
      #   # create a purchase if not exist
      #   sale   = Sale.find_by_reference_number(r.delivery_number)
      #   sale ||= Sale.create!(:state => r.order_status, :currency => "EUR", :nature_id => purchase_nature.id, :reference_number => r.order_number, :supplier_id => coop.id, :planned_on => r.ordered_on, :created_on => r.ordered_on)
      #   tax_price_nature_appro = Tax.find_by_amount(19.6)
      #   # create a product_nature if not exist
      #   product_nature   = ProductNature.find_by_name(r.product_nature_name)
      #   product_nature ||= ProductNature.create!(:stock_account_id => stock_account_nature_coop.id, :charge_account_id => charge_account_nature_coop.id, :name => r.product_nature_name, :number => r.product_nature_name,  :saleable => false, :purchasable => true, :active => true, :storable => true, :variety_id => b.id, :unit_id => unit_u.id, :category_id => ProductNatureCategory.by_default.id)
      #   # create a product (Matter) if not exist
      #   product   = Matter.find_by_name(r.matter_name)
      #   product ||= Matter.create!(:name => r.matter_name, :identification_number => r.matter_name, :work_number => r.matter_name, :born_at => Time.now, :nature_id => product_nature.id, :owner_id => Entity.of_company.id, :number => r.matter_name) #
      #   # create a product_price_template if not exist
      #   product_price   = ProductPriceTemplate.find_by_product_nature_id_and_supplier_id_and_assignment_pretax_amount(product_nature.id, coop.id, r.product_unit_price)
      #   product_price ||= ProductPriceTemplate.create!(:currency => "EUR", :assignment_pretax_amount => r.product_unit_price, :product_nature_id => product_nature.id, :tax_id => tax_price_nature_appro.id, :supplier_id => coop.id)
      #   # create a purchase_item if not exist
      #   # purchase_item   = PurchaseItem.find_by_product_id_and_purchase_id_and_price_id(product.id, purchase.id, product_price.id)
      #   # purchase_item ||= PurchaseItem.create!(:quantity => r.quantity, :unit_id => unit_u.id, :price_id => product_price.id, :product_id => product.id, :purchase_id => purchase.id)
      #   purchase.items.create!(:quantity => r.quantity, :product_id => product.id)
      #   # create an incoming_delivery if status => 2

      #   # create an incoming_delivery_item if status => 2


      #   print "."
      # end
      # puts "!"

      #############################################################################
      # import Milk result to make automatic quality indicators
      # @TODO
      #
      # set the lab
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Milk tank analysis (from LILCO) "
      # set the product if not exist
      milk_unit = "liter"
      # @TODO = appeller la méthode des comptes comme dans la nomenclature accounts
      stock_account_nature_milk = Account.find_by_number("321")
      sale_account_nature_milk = Account.find_by_number("701")
      product_nature_milk_category = ProductNatureCategory.find_by_name("Défaut")
      # variety_milk = ProductVariety.find_by_code("normande")
      # add a product_nature
      product_nature   = ProductNature.find_by_name("lait_vache")
      product_nature ||= ProductNature.create!(:stock_account_id => stock_account_nature_milk.id, :product_account_id => sale_account_nature_milk.id, :name => "lait", :number => "LAIT", :saleable => true, :purchasable => false, :active => true, :storable => true, :variety => "bos", :derivative => "milk", :unit => milk_unit, :category_id => product_nature_milk_category.id)

      # create a generic product to link analysis_indicator
      product   = Matter.find_by_name("lait_vache")
      product ||= Matter.create!(:name => "lait_vache", :identification_number => "lait_2010-2013", :work_number => "lait_2011_2013", :born_at => Time.now, :nature_id => product_nature.id, :owner_id => Entity.of_company.id, :number => "L2011-2013") #

      # mention all unit for indicator relative to milk_analysis_quality
      # create all indicator relative to milk_analysis_quality if not exist
      # product_indicator_germes = ProductNatureIndicator.find_by_name("germes_totaux")
      # product_indicator_germes ||= ProductNatureIndicator.create!(:product_nature_id => product_nature.id, :name => "germes_totaux", :description => "Dénombrement des micro-organismes totaux obtenues à 30°C - (x1000 germes / ml)- NF EN ISO 4833",:nature => "measure", :usage => "production", :active => true, :created_at => Time.now, :unit => unit_analysis_measure_germes, :maximal_value => "5000.0000")
#
      # product_indicator_inhib = ProductNatureIndicator.find_by_name("inhibiteurs")
      # product_indicator_inhib ||= ProductNatureIndicator.create!(:product_nature_id => product_nature.id, :name => "inhibiteurs", :description => "Recherche des résidus d’inhibiteurs par test microbiologique - (NEGATIF / POSITIF)- protocole CNIEL INHD",:nature => "string", :usage => "production", :active => true, :created_at => Time.now, :maximal_length => 3)
#
      # product_indicator_mg = ProductNatureIndicator.find_by_name("matieres_grasse")
      # product_indicator_mg ||= ProductNatureIndicator.create!(:product_nature_id => product_nature.id, :name => "matieres_grasse", :description => "Détermination de la teneur en matière grasse par méthode acido-butyrométrique - (g / L)- NF AFNOR V 04-210",:nature => "measure", :usage => "production", :active => true, :created_at => Time.now, :unit_id => unit_l.id, :maximal_value => "60.0000")
#
      # product_indicator_mp = ProductNatureIndicator.find_by_name("matieres_proteique")
      # product_indicator_mp ||= ProductNatureIndicator.create!(:product_nature_id => product_nature.id, :name => "matieres_proteique", :description => "Détermination de la teneur en protéine par la méthode au Noir Amido - (g / L)- NF AFNOR V 04-216",:nature => "measure", :usage => "production", :active => true, :created_at => Time.now, :unit_id => unit_l.id, :maximal_value => "60.0000")
#
      # product_indicator_cellules = ProductNatureIndicator.find_by_name("cellules")
      # product_indicator_cellules ||= ProductNatureIndicator.create!(:product_nature_id => product_nature.id, :name => "cellules", :description => "Dénombrement des cellules somatiques - (x1000 cellules / ml)- ISO 13366-2",:nature => "measure", :usage => "production", :active => true, :created_at => Time.now, :unit_id => unit_ml.id, :maximal_value => "8000.0000")
#
      # product_indicator_buty = ProductNatureIndicator.find_by_name("butyriques")
      # product_indicator_buty ||= ProductNatureIndicator.create!(:product_nature_id => product_nature.id, :name => "butyriques", :description => "Dénombrement microbiologique des spores de Clostridia  - (spores / L)- protocole CNIEL BUTY",:nature => "measure", :usage => "production", :active => true, :created_at => Time.now, :unit_id => unit_l.id, :maximal_value => "50000.0000")
#
      # product_indicator_cryo = ProductNatureIndicator.find_by_name("cryoscopie")
      # product_indicator_cryo ||= ProductNatureIndicator.create!(:product_nature_id => product_nature.id, :name => "cryoscopie", :description => "Détermination du point de congélation par cryoscopie - (°C)- NF EN ISO 5764",:nature => "decimal", :usage => "production", :active => true, :created_at => Time.now, :unit_id => unit_u.id, :maximal_value => "0.580")
#
      # product_indicator_lipo = ProductNatureIndicator.find_by_name("lipolyse")
      # product_indicator_lipo ||= ProductNatureIndicator.create!(:product_nature_id => product_nature.id, :name => "lipolyse", :description => " Méthode aux Savons de Cuivre - ( meq /100 g de MG)- protocole CNIEL LIPO",:nature => "decimal", :usage => "production", :active => true, :created_at => Time.now, :unit_id => unit_u.id, :maximal_value => "2.0")
#
      # product_indicator_igg = ProductNatureIndicator.find_by_name("igg")
      # product_indicator_igg ||= ProductNatureIndicator.create!(:product_nature_id => product_nature.id, :name => "igg", :description => "Dosage des IgG par immunodiffusion radiale - (u / L)- d’après D. Levieux",:nature => "string", :usage => "production", :active => true, :created_at => Time.now)
#
      # product_indicator_uree = ProductNatureIndicator.find_by_name("uree")
      # product_indicator_uree ||= ProductNatureIndicator.create!(:product_nature_id => product_nature.id, :name => "uree", :description => "Dosage de la teneur moyenne en urée - (mg / L)",:nature => "decimal", :usage => "production", :active => true, :created_at => Time.now, :unit_id => unit_u.id, :maximal_value => "600.00")
#

      trans_inhib = {
        "NEG" => "negative",
        "POS" => "positive"
      }

     for a in ["total_bacteria_concentration", "inhibitors_presence", "fat_matters_concentration", "protein_matters_concentration", "cells_concentration", "clostridial_spores_concentration", "freezing_point_temperature", "lipolysis", "immunoglobulins_concentration", "urea_concentration"]
      product_nature_indicator = ProductNatureIndicator.where(:nature => a, :product_nature_id => product_nature.id ).first
      product_nature_indicator ||= ProductNatureIndicator.create!(:product_nature_id => product_nature.id, :nature => a)
     end

      file = Rails.root.join("test", "fixtures", "files", "HistoIP_V.csv")
      CSV.foreach(file, :encoding => "CP1252", :col_sep => "\t", :headers => true) do |row|
        analysis_on = Date.civil(row[0].to_i, row[1].to_i, 1)
        r = OpenStruct.new(:analysis_year => row[0],
                           :analysis_month => row[1],
                           :analysis_order => row[2],
                           :analysis_quality_indicator_germes => (row[3].blank? ? 0 : row[3].to_i),
                           :analysis_quality_indicator_inhib => (row[4].blank? ? "negative" : trans_inhib[row[4]]),
                           :analysis_quality_indicator_mg => (row[5].blank? ? 0 : (row[5].to_d)/100),
                           :analysis_quality_indicator_mp => (row[6].blank? ? 0 : (row[6].to_d)/100),
                           :analysis_quality_indicator_cellules => (row[7].blank? ? 0 : row[7].to_i),
                           :analysis_quality_indicator_buty => (row[8].blank? ? 0 : row[8].to_i),
                           :analysis_quality_indicator_cryo => (row[9].blank? ? 0.00 : row[9].to_d),
                           :analysis_quality_indicator_lipo => (row[10].blank? ? 0.00 : row[10].to_d),
                           :analysis_quality_indicator_igg => (row[11].blank? ? "0" : row[11].to_s),
                           :analysis_quality_indicator_uree => (row[12].blank? ? 0 : row[12].to_i),
                           :analysis_quality_indicator_salmon => row[13],
                           :analysis_quality_indicator_listeria => row[14],
                           :analysis_quality_indicator_staph => row[15],
                           :analysis_quality_indicator_coli => row[16],
                           :analysis_quality_indicator_pseudo => row[17],
                           :analysis_quality_indicator_ecoli => row[18]
                           )
        # create an indicator for each line of analysis (based onn milk analysis indicator in XML nomenclature)
        product.indicator_data.create!(:indicator => "total_bacteria_concentration", :value => r.analysis_quality_indicator_germes ,:measure_unit => "thousands_per_milliliter" ,:measured_at => analysis_on )
        product.indicator_data.create!(:indicator => "inhibitors_presence", :value => r.analysis_quality_indicator_inhib ,:measured_at => analysis_on )
        product.indicator_data.create!(:indicator => "fat_matters_concentration", :value => r.analysis_quality_indicator_mg ,:measure_unit => "gram_per_liter", :measured_at => analysis_on )
        product.indicator_data.create!(:indicator => "protein_matters_concentration", :value => r.analysis_quality_indicator_mp ,:measure_unit => "gram_per_liter", :measured_at => analysis_on )
        product.indicator_data.create!(:indicator => "cells_concentration", :value => r.analysis_quality_indicator_cellules ,:measure_unit => "thousands_per_milliliter", :measured_at => analysis_on )
        product.indicator_data.create!(:indicator => "clostridial_spores_concentration", :value => r.analysis_quality_indicator_buty ,:measure_unit => "unities_per_liter", :measured_at => analysis_on )
        product.indicator_data.create!(:indicator => "freezing_point_temperature", :value => r.analysis_quality_indicator_cryo ,:measure_unit => "celsius", :measured_at => analysis_on )
        product.indicator_data.create!(:indicator => "lipolysis", :value => r.analysis_quality_indicator_lipo ,:measure_unit => "thousands_eq_per_hundred_gram", :measured_at => analysis_on )
        product.indicator_data.create!(:indicator => "immunoglobulins_concentration", :value => r.analysis_quality_indicator_igg ,:measure_unit => "unities_per_liter", :measured_at => analysis_on )
        product.indicator_data.create!(:indicator => "urea_concentration", :value => r.analysis_quality_indicator_uree , :measure_unit => "milligram_per_liter", :measured_at => analysis_on )

        print "."
      end
      puts "!"

      #############################################################################
      # import some base activities from CSV
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Activities: "

      # attributes to map family
      families = {
        "CEREA" => :vegetal,
        "COPLI" => :vegetal,
        "CUFOU" => :vegetal,
        "ANIMX" => :animal,
        "XXXXX" => :none,
        "NINCO" => :none
      }
      # attributes to map nature
      natures = {
        "PRINC" => :main,
        "AUX" => :auxiliary,
        "" => :none
      }
      # Load file
      file = Rails.root.join("test", "fixtures", "files", "activities_ref_demo.csv")
      CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => false, :quote_char => "'") do |row|
        r = OpenStruct.new(:nomen => row[0],
                           :name => row[1].downcase.capitalize,
                           :family => (families[row[2]] || :none).to_s,
                           :area_unit => "hectare",
                           :work_unit => "unity",
                           :product_nature_name => row[5],
                           :nature => (natures[row[6]] || :none).to_s
                           )
        # Create an activity if not exist
        activity = Activity.find_by_nomen(r.nomen)
        activity ||= Activity.create!(:nature => r.nature, :description => "Import from reference", :family => r.family, :name => r.name, :nomen => r.nomen)

        # TODO: Add Watchings
        # activity.watchings.create!(:product_nature_id => ???, :work_unit_id => r.work_unit.id, :area_unit_id => r.area_unit.id)
        print "."
      end
      puts "!"

      #############################################################################
      # import Bank Cash from CRCA
      #
      # TODO : Retrieve data and put it into bank_statement
      #
      # file = Rails.root.join("test", "fixtures", "files", "bank-rb.ofx")
      # FIXME OfxParser don't work....
      # ofx = OfxParser::OfxParser.parse(open(file))
      # ofx.bank_accounts.each do |bank_account|
      #   bank_account.id # => "492108"
      #   bank_account.bank_id # => "1837"
      #   bank_account.currency # => "GBP"
      #   bank_account.type # => :checking
      #   bank_account.balance.amount # => "100.00"
      #   bank_account.balance.amount_in_pennies # => "10000"
      # end
      # puts "!"


      puts "Total time: #{(Time.now - start).round(2)}s"
    end
  end
end
