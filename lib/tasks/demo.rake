# -*- coding: utf-8 -*-

require 'ostruct'

namespace :db do
  desc "Build demo data"
  task :demo => :environment do
    STDOUT.sync = true
    puts "Started: "
    ActiveRecord::Base.transaction do

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
      fy.started_on = Date.civil(2000,1,1)
      fy.stopped_on = Date.civil(2000,12,31)
      fy.code = "EX2000"
      fy.save!
      en_org = EntityNature.where(:gender => :undefined).first

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
            entity = Entity.create!(:last_name => r.entity_name.mb_chars.capitalize, :nature_id => en_org.id, :supplier_account_id => r.account_id, :picture => f, :origin => r.entity_name)
            f.close
            entity.addresses.create!(:canal => :email, :coordinate => ["contact", "info", r.entity_name.parameterize].sample + "@" + r.entity_name.parameterize + "." + ["fr", "com", "org", "eu"].sample)
            entity.addresses.create!(:canal => :phone, :coordinate => "+33" + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s)
          end
        end
        if r.account.number.match(/^411/)
          unless Entity.find_by_origin(r.entity_name)
            f = File.open(picture_undefined)
            entity = Entity.create!(:last_name => r.entity_name.mb_chars.capitalize, :nature_id => en_org.id, :client_account_id => r.account_id, :picture => f, :origin => r.entity_name)
            f.close
            entity.addresses.create!(:canal => :email, :coordinate => ["contact", "info", r.entity_name.parameterize].sample + "@" + r.entity_name.parameterize + "." + ["fr", "com", "org", "eu"].sample)
            entity.addresses.create!(:canal => :phone, :coordinate => "+33" + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s + rand(10).to_s)
          end
        end

        print "."
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

      # Import synel
      h = ProductVariety.find_by_code("cattle")
      p = ProductVariety.find_by_code("animal")
      h ||= ProductVariety.create!(:name => "Bovin", :code => "cattle", :product_type => "Animal", :parent_id => (p ? p.id : nil))
      v = ProductVariety.find_by_code("normande")
      v ||= ProductVariety.create!(:name => "Normande", :code => "normande", :product_type => "Animal", :parent_id => (h ? h.id : nil))
      unit = Unit.find_by_base("")
      # add default variety for building
      b = ProductVariety.find_by_code("animal_house")
      q = ProductVariety.find_by_code("building")
      b ||= ProductVariety.create!(:name => "Bâtiments Animaux", :code => "animal_house", :product_type => "Warehouse", :parent_id => (q ? q.id : nil))
      # add default category for all
      category = ProductNatureCategory.first
      category ||= ProductNatureCategory.create!(:name => "Défaut")
      # add default groups for animal
      group1 = ProductGroup.find_by_name("VL")
      group1 ||= ProductGroup.create!(:name => "VL", :description => "Vache Laitière")
      group2 = ProductGroup.find_by_name("GEN")
      group2 ||= ProductGroup.create!(:name => "GEN", :description => "Génisses")
      group3 = ProductGroup.find_by_name("VEAU")
      group3 ||= ProductGroup.create!(:name => "VEAU", :description => "Veaux")
      group4 = ProductGroup.find_by_name("TAURILLON")
      group4 ||= ProductGroup.create!(:name => "TAURILLON", :description => "Taurillons")
      # create default product_nature to place animal
      place_nature = ProductNature.find_by_number("CATTLE_HOUSE")
      place_nature ||= ProductNature.create!(:name => "Stabulation", :number => "CATTLE_HOUSE", :storage => true, :indivisible => true, :variety_id => b.id, :unit_id => unit.id, :category_id => category.id)
      # create default product_nature to create animal
      cow = ProductNature.find_by_number("CATTLE")
      cow ||= ProductNature.create!(:name => "Bovin", :number => "CATTLE", :alive => true, :storable => true, :indivisible => true, :variety_id => v.id, :unit_id => unit.id, :category_id => category.id)
      # create default product to place animal
      place = Warehouse.find_by_work_number("STABU_01")
      place ||= Warehouse.create!(:name => "Stabulation principale", :identification_number => "S0001", :number => "STABU_01",:work_number => "STABU_01", :born_at => Time.now, :reservoir => true, :content_nature_id => cow.id, :variety_id => b.id, :nature_id => place_nature.id, :owner_id => Entity.of_company.id)

      arrival_causes = {"N" => :birth, "A" => :purchase, "P" => :housing, "" => :other }
      departure_causes = {"M" => :death, "B" => :sale, "" => :other, "C" => :consumption , "E" => :sale}


      file = Rails.root.join("test", "fixtures", "files", "animals-synel17.csv")
      pictures = Dir.glob(Rails.root.join("test", "fixtures", "files", "animals", "*.jpg"))
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
        animal = Animal.create!(:name => r.name, :identification_number => r.identification_number, :work_number => r.work_number, :born_at => r.born_on, :sex => r.sex, :picture => f, :nature_id => cow.id, :number => r.work_number, :owner_id => Entity.of_company.id, :reproductor => (r.sex == :male ? rand(2).zero? : false))
        f.close
        # place the current animal in the default place (stabulation) with dates
        ProductLocalization.create!(:container_id => place.id, :product_id => animal.id, :nature => :interior, :transfer_id => place.id, :started_at => r.arrived_on, :stopped_at => r.departed_on, :arrival_cause => r.arrival_cause, :departure_cause => r.departure_cause)
        # place the current animal in the default group with dates
        # @TODO set correct group if sex M / F and age > 2 year
        # group1 if sex = female and age > 3 years
        # group2 if sex = female and age between 1 and 3 years
        # group3 if  age < 3 month
        # group4 if sex = male and age > 1 years
        ProductMembership.create!(:product_id => animal.id, :group_id => group1.id,:started_at => r.arrived_on, :stopped_at => r.departed_on )
        print "c"
      end

      # Assign parents
      Animal.where(:nature_id => cow.id).find_each do |animal|
        animal.father = Animal.fathers.where("born_at <= ?", (animal.born_at - 45.months)).to_a.sample rescue nil
        animal.mother = Animal.mothers.where("born_at <= ?", (animal.born_at - 36.months)).to_a.sample rescue nil
        animal.save!
      end

      # Import shapefile
      v = ProductVariety.find_by_code("land_parcel")
      p = ProductVariety.find_by_code("place")
      v ||= ProductVariety.create!(:name => "Parcelle", :code => "land_parcel", :product_type => "LandParcel", :parent_id => (p ? p.id : nil))
      unit = Unit.get(:m2)
      category = ProductNatureCategory.first
      category ||= ProductNatureCategory.create!(:name => "Défaut")
      land_parcel = ProductNature.find_by_number("LANDPARCEL")
      land_parcel ||= ProductNature.create!(:name => "Parcelle", :number => "LANDPARCEL", :variety_id => v.id, :unit_id => unit.id, :category_id => category.id)
      RGeo::Shapefile::Reader.open(Rails.root.join("test", "fixtures", "files", "land_parcels-shapefile.shp").to_s) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          LandParcel.create!(:shape => record.geometry, :name => Faker::Name.first_name, :number => record.attributes['PACAGE'].to_s + record.attributes['CAMPAGNE'].to_s + record.attributes['NUMERO'].to_s, :born_at => Date.civil(2000,1,1), :nature_id => land_parcel.id, :owner_id => Entity.of_company.id)
          # puts "Record number #{record.index}:"
          # puts "  Geometry: #{record.geometry.as_text}"
          # puts "  Attributes: #{record.attributes.inspect}"
          print "p"
        end
      end

      #
      #
      #
      # Create variety for wheat product
      entitycat = EntityCategory.find_by_code("PARDEFAU")
      category1 ||= ProductNatureCategory.create!(:name => "Vente")
      b = ProductVariety.find_by_code("matter")
      b ||= ProductVariety.create!(:name => "Matière vegetale", :code => "matter", :product_type => "Vegetal", :parent_id => (b ? b.id : nil))
      c = ProductVariety.find_by_code("caphorn")
      c ||= ProductVariety.create!(:name => "CAPHORN", :code => "caphorn", :product_type => "Vegetal", :parent_id => (b ? b.id : nil))
      unit_v = Unit.find_by_name("t")
      # Create product_nature for wheat product
      charge_account_nature_ble = Account.find_by_number("601")
      product_account_nature_ble = Account.find_by_number("701")
      nature_ble = ProductNature.find_by_number("BLE")
      nature_ble ||= ProductNature.create!(:charge_account_id => charge_account_nature_ble.id,:product_account_id => product_account_nature_ble.id,:name => "Blé", :number => "BLE", :alive => true, :saleable => true, :purchasable => true, :active => true, :storable => true, :variety_id => c.id, :unit_id => unit_v.id, :category_id => category1.id)
      taxe_prix_nature_ble = Tax.find_by_amount('5.5000')
      # Create product_nature_price for wheat product
      prix_nature_ble = ProductNaturePrice.find_by_product_nature_id(nature_ble.id)
      prix_nature_ble ||= ProductNaturePrice.create!(:amount => "211.0000", :currency => "EUR", :pretax_amount => "200.0000", :product_nature_id => nature_ble.id, :tax_id => taxe_prix_nature_ble.id, :category_id => entitycat.id, :supplier_id => Entity.of_company.id )
      # Create wheat product
      ble = Vegetal.find_by_work_number("BLE_001")
      ble = Vegetal.create!(:name => "Blé Cap Horn 2011", :identification_number => "BLE_2011_07142011", :work_number => "BLE_2011", :born_at => "2011-07-14", :nature_id => nature_ble.id, :number => "BLE_2011", :owner_id => Entity.of_company.id)

      # sale_nature
      sale_nature = SaleNature.find_by_name("Coop")
      sale_nature ||= SaleNature.create!(:name => "Coop", :currency => "EUR")
      # sale
      sale = Sale.create!( :created_on => '2013-02-27', :client_id => '2', :nature_id => sale_nature.id, :number => "V201302000002", :sum_method => "wt", :state => "draft")
      # sale_item
      sale_item1 = SaleItem.create!(:quantity => '5.0000', :tax_id => taxe_prix_nature_ble.id, :unit_id => unit_v.id, :price_id => prix_nature_ble.id, :product_id => ble.id, :sale_id => sale.id)
      sale_item2 = SaleItem.create!(:quantity => '15.0000', :tax_id => taxe_prix_nature_ble.id, :unit_id => unit_v.id, :price_id => prix_nature_ble.id, :product_id => ble.id, :sale_id => sale.id)

      #import Coop Order to make automatic purchase
      #@ To finish with two level (purchases and purchases_lines)
      # 
      # set the coop
      coop = Entity.find_by_full_name("Kazeni")
      unit_u = Unit.find_by_name("u")
      # add a Coop purchase_nature
      purchase_nature = PurchaseNature.find_by_name("Coop")
      purchase_nature ||= PurchaseNature.create!(:name => "Coop", :currency => "EUR")
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
                           :product_order_quantity => row[5].to_d,
                           :product_deliver_quantity => row[6].to_d,
                           :product_unit_price => row[7].to_d,
                           :order_status => (status[row[8]] || :draft)
                           )
        # create a purchase if not exist
        purchase_order = Purchase.find_by_reference_number(r.order_number)
        purchase_order ||= Purchase.create!(:state => r.order_status,:currency => "EUR", :nature_id => purchase_nature.id, :reference_number => r.order_number, :supplier_id => coop.id, :planned_on => r.ordered_on,:created_on => r.ordered_on)
        taxe_prix_nature_appro = Tax.find_by_amount('19.6000')
        # create a product_nature if not exist
        product_nature_order = ProductNature.find_by_name(r.product_nature_name) 
        product_nature_order ||= ProductNature.create!(:stock_account_id => stock_account_nature_coop.id,:charge_account_id => charge_account_nature_coop.id,:name => r.product_nature_name, :number => r.product_nature_name, :alive => false, :saleable => false, :purchasable => true, :active => true, :storable => true, :variety_id => b.id, :unit_id => unit_u.id, :category_id => r.product_nature_category.id)
        # create a product (Matter) if not exist
        product_order = Matter.find_by_name(r.matter_name) 
        product_order ||= Matter.create!(:name => r.matter_name, :identification_number => r.matter_name, :work_number => r.matter_name, :born_at => Time.now, :nature_id => product_nature_order.id, :number => r.matter_name, :owner_id => Entity.of_company.id)
        # create a product_nature_price if not exist
        product_order_price = ProductNaturePrice.find_by_product_nature_id_and_supplier_id_and_pretax_amount(product_nature_order.id,coop.id,r.product_unit_price)
        product_order_price ||= ProductNaturePrice.create!(:amount => ((r.product_unit_price*(taxe_prix_nature_appro.amount/100))+r.product_unit_price), :currency => "EUR", :pretax_amount => r.product_unit_price, :product_nature_id => product_nature_order.id, :tax_id => taxe_prix_nature_appro.id, :category_id => entitycat.id, :supplier_id => coop.id )
        # create a purchase_item if not exist
        purchase_order_item = PurchaseItem.find_by_product_id_and_purchase_id_and_price_id(product_order.id,purchase_order.id,product_order_price.id)  
        purchase_order_item ||= PurchaseItem.create!(:quantity => r.product_order_quantity, :unit_id => unit_u.id, :price_id => product_order_price.id, :product_id => product_order.id, :purchase_id => purchase_order.id)
        # create an incoming_delivery if status => 2
        
        # create an incoming_delivery_item if status => 2
       
       
        print "o"
      end

      puts "!"
    end
  end
end
