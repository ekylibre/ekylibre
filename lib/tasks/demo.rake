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

      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] JournalEntryLines - CERPC General ledger: "
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
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Animals - Synel animals inventory : "
      # h = ProductVariety.find_by_code("cattle")
      # p = ProductVariety.find_by_code("animal")
      # h ||= ProductVariety.create!(:name => "Bovin", :code => "cattle", :product_type => "Animal", :parent_id => (p ? p.id : nil))
      # v = ProductVariety.find_by_code("normande")
      # v ||= ProductVariety.create!(:name => "Normande", :code => "normande", :product_type => "Animal", :parent_id => (h ? h.id : nil))

      # add default product_nature for animals
      animal_product_nature_category = ProductNatureCategory.find_by_name("Produits animaux")
      animal_product_nature_category ||= ProductNatureCategory.create!(:name => "Produits animaux", :published => true)
      cow_unit = "head"
      cow_product_account = Account.find_in_chart(:adult_animal_product)
      cow_stock_account = Account.find_in_chart(:long_time_animal_stock)

      for attributes in [{:name => "Vache Laitière",:number => "VACHE_LAITIERE", :description => "Vache Laitière",
                          :indicators => "weight, animal_life_state, mammalia_reproduction_event_abortion, mammalia_reproduction_method_embryo_transplant, mammalia_born_cycle, mammalia_reproduction_state, mammalia_twins_condition, mammalia_lactation_state, animal_disease_state"
                          },
                         {:name => "Génisse Laitière",:number => "GENISSE", :description => "Génisse Laitière",
                          :indicators => "weight, animal_life_state, mammalia_reproduction_event_abortion, mammalia_reproduction_method_embryo_transplant, mammalia_born_cycle, mammalia_reproduction_state, mammalia_twins_condition, mammalia_lactation_state, animal_disease_state"
                           },
                         {:name => "Taurillon",:number => "TAURILLON", :description => "Taurillon",
                          :indicators => "weight, animal_life_state, animal_disease_state"
                           },
                         {:name => "Taureau",:number => "TAUREAU", :description => "Taureau reproducteur",
                          :indicators =>"isu, inel, tb, tp"
                          },
                         {:name => "Veau",:number => "VEAU", :description => "Veau laitier 8-15j",
                          :indicators =>"weight, animal_life_state, animal_disease_state, mammalia_born_condition"
                           }
                        ]
        unless ProductNature.find_by_number(attributes[:number])
          cow_pn = ProductNature.create!({:unitary => true, :category_id => animal_product_nature_category.id, :individual => true, :product_account_id => cow_product_account.id, :variety => "bos", :storable => true, :stock_account_id => cow_stock_account.id, :saleable => true}.merge(attributes) )
          cow_pn.variants.create!(:active => true, :commercial_name => cow_pn.name, :name => cow_pn.name,
                              :purchase_indicator => "weight", :purchase_indicator_unit => "kilogram",
                              :sale_indicator => "weight", :sale_indicator_unit => "kilogram",
                              :usage_indicator => "weight", :usage_indicator_unit => "kilogram"
                              )
        end
      end

     cow_vl = ProductNatureVariant.find_by_nature_name("Vache Laitière")
     cow_gen = ProductNatureVariant.find_by_nature_name("Génisse Laitière")
     cow_v = ProductNatureVariant.find_by_nature_name("Veau")
     cow_taur = ProductNatureVariant.find_by_nature_name("Taurillon")
     cow_trepro = ProductNatureVariant.find_by_nature_name("Taureau")

      # add default groups for animal

      for attributes in [{:name => "Vaches Latières", :description => "Vaches Laitières", :work_number => "VL", :nature_id => cow_vl.nature.id ,:variant_id => cow_vl.id},
                         {:name => "Génisses 3", :description => "Génisses 3", :work_number => "GEN_3", :nature_id => cow_gen.nature.id, :variant_id => cow_gen.id},
                         {:name => "Génisses 2", :description => "Génisses 2", :work_number => "GEN_2", :nature_id => cow_gen.nature.id, :variant_id => cow_gen.id},
                         {:name => "Génisses 1", :description => "Génisses 2", :work_number => "GEN_1", :nature_id => cow_gen.nature.id, :variant_id => cow_gen.id},
                         {:name => "Veaux Niche", :description => "Veaux en niche individuel", :work_number => "VEAU_NICHE", :nature_id => cow_v.nature.id, :variant_id => cow_v.id},
                         {:name => "Veaux Poulailler 1", :description => "Veaux Poulailler 1", :work_number => "VEAU_1", :nature_id => cow_v.nature.id, :variant_id => cow_v.id},
                         {:name => "Veaux Poulailler 2", :description => "Veaux Poulailler 2", :work_number => "VEAU_2", :nature_id => cow_v.nature.id, :variant_id => cow_v.id},
                         {:name => "Taurillons case 7", :description => "Taurillon case 7 (côté Hangar)", :work_number => "TAUR_7", :nature_id => cow_taur.nature.id, :variant_id => cow_taur.id},
                         {:name => "Taurillons case 6", :description => "Taurillon case 6", :work_number => "TAUR_6", :nature_id => cow_taur.nature.id, :variant_id => cow_taur.id},
                         {:name => "Taurillons case 5", :description => "Taurillon case 5", :work_number => "TAUR_5", :nature_id => cow_taur.nature.id, :variant_id => cow_taur.id},
                         {:name => "Taurillons case 4", :description => "Taurillon case 4", :work_number => "TAUR_4", :nature_id => cow_taur.nature.id, :variant_id => cow_taur.id},
                         {:name => "Taurillons case 3", :description => "Taurillon case 3", :work_number => "TAUR_3", :nature_id => cow_taur.nature.id, :variant_id => cow_taur.id},
                         {:name => "Taurillons case 2", :description => "Taurillon case 2", :work_number => "TAUR_2", :nature_id => cow_taur.nature.id, :variant_id => cow_taur.id},
                         {:name => "Taurillons case 1", :description => "Taurillon case 1", :work_number => "TAUR_1", :nature_id => cow_taur.nature.id, :variant_id => cow_taur.id}
                        ]
        unless AnimalGroup.find_by_work_number(attributes[:work_number])
          AnimalGroup.create!({:active => true, :variety => "bos", :owner_id => Entity.of_company.id}.merge(attributes) )
        end
      end

      # create default product_nature to place animal
      building_product_nature_category = ProductNatureCategory.find_by_name("Bâtiments")
      building_product_nature_category ||= ProductNatureCategory.create!(:name => "Bâtiments", :published => true)
      place_nature_animal = ProductNature.find_by_number("BATIMENT_ANIMAUX")
      place_nature_animal ||= ProductNature.create!(:name => "Bâtiment d'accueil animaux", :number => "BATIMENT_ANIMAUX", :variety => "building", :category_id => building_product_nature_category.id)
      place_nature_animal.variants.create!(:active => true, :commercial_name => place_nature_animal.name,:name => place_nature_animal.name,
                                            :purchase_indicator => "net_surperficial_area", :purchase_indicator_unit => "square_meter",
                                            :sale_indicator => "net_surperficial_area", :sale_indicator_unit => "square_meter",
                                            :usage_indicator => "net_surperficial_area", :usage_indicator_unit => "square_meter"
                                            )
      place_variant = ProductNatureVariant.find_by_nature_name("Bâtiment d'accueil animaux")

      # create default building to place animal

      for attributes in [{:name => "Stabulation principale", :work_number => "STABULATION", :nature_id => place_variant.nature.id, :variant_id => place_variant.id, :content_nature_id => cow_vl.nature.id},
                         {:name => "Batiment Taurillons Bois 7 cases", :work_number => "BAT_TAURILLON", :nature_id => place_variant.nature.id, :variant_id => place_variant.id, :content_nature_id => cow_taur.nature.id},
                         {:name => "Batiment Bouquet en L Genisse", :work_number => "BAT_GEN", :nature_id => place_variant.nature.id, :variant_id => place_variant.id, :content_nature_id => cow_gen.nature.id},
                         {:name => "Batiment Bois Nurserie 2 cases", :work_number => "BAT_BOIS_VEAU", :nature_id => place_variant.nature.id, :variant_id => place_variant.id, :content_nature_id => cow_v.nature.id},
                         {:name => "Poulailler 1 (côté Jardin)", :work_number => "BAT_POULAILLER_1", :nature_id => place_variant.nature.id, :variant_id => place_variant.id, :content_nature_id => cow_v.nature.id},
                         {:name => "Poulailler 2 (côté Forêt)", :work_number => "BAT_POULAILLER_2", :nature_id => place_variant.nature.id, :variant_id => place_variant.id, :content_nature_id => cow_v.nature.id}
                        ]
        unless Building.find_by_work_number(attributes[:work_number])
          Building.create!({:owner_id => Entity.of_company.id, :variety => "building", :born_at => Time.now, :reservoir => true}.merge(attributes) )
        end
      end


      # set finder for creating animal
      place_v = Building.find_by_work_number("BAT_BOIS_VEAU")
      group_v = AnimalGroup.find_by_work_number("VEAU_1")
      place_gen = Building.find_by_work_number("BAT_GEN")
      group_gen1 = AnimalGroup.find_by_work_number("GEN_1")
      group_gen2 = AnimalGroup.find_by_work_number("GEN_2")
      group_gen3 = AnimalGroup.find_by_work_number("GEN_3")
      place_taur = Building.find_by_work_number("BAT_TAURILLON")
      group_taur = AnimalGroup.find_by_work_number("TAUR_7")
      place_vl = Building.find_by_work_number("STABULATION")
      group_vl = AnimalGroup.find_by_work_number("VL")

      arrival_causes = {"N" => :birth, "A" => :purchase, "P" => :housing, "" => :other }
      departure_causes = {"M" => :death, "B" => :sale, "" => :other, "C" => :consumption , "E" => :sale}


      file = Rails.root.join("test", "fixtures", "files", "animals-synel17.csv")
      pictures = Dir.glob(Rails.root.join("test", "fixtures", "files", "animals-ld", "*.jpg"))
      photo_taur = Rails.root.join("test", "fixtures", "files", "animals", "taurillon.jpg")
      photo_v = Rails.root.join("test", "fixtures", "files", "animals", "veau.jpg")
      CSV.foreach(file, :encoding => "CP1252", :col_sep => ";", :headers => true) do |row|
        next if row[4].blank?
        r = OpenStruct.new(:country => row[0],
                           :identification_number => row[1],
                           :work_number => row[2],
                           :name => (row[3].blank? ? Faker::Name.first_name+"(MN)" : row[3].capitalize),
                           :born_on => (row[4].blank? ? nil : Date.civil(*row[4].to_s.split(/\//).reverse.map(&:to_i))),
                           :corabo => row[5],
                           :sex => (row[6] == "F" ? :female : :male),
                           :arrival_cause => (arrival_causes[row[7]] || row[7]),
                           :arrived_on => (row[8].blank? ? nil : Date.civil(*row[8].to_s.split(/\//).reverse.map(&:to_i))),
                           :departure_cause => (departure_causes[row[9]] ||row[9]),
                           :departed_on => (row[10].blank? ? nil : Date.civil(*row[10].to_s.split(/\//).reverse.map(&:to_i)))
                           )


        # case = VEAU
        if r.born_on > (Date.today - 3.months) and r.born_on < (Date.today)
          f = File.open(photo_v)
          animal = Animal.create!(:variant_id => cow_v.id, :name => r.name, :variety => "bos", :identification_number => r.identification_number,
                                  :work_number => r.work_number, :born_at => r.born_on, :dead_at => r.departed_on,
                                  :sex => r.sex, :picture => f, :owner_id => Entity.of_company.id, :reproductor => false
                                 )
          f.close
          # set default indicators
          animal.indicator_data.create!(:indicator => "weight", :value => "55.45" ,:measure_unit => "kilogram" ,:measured_at => r.born_on.to_datetime )
          animal.indicator_data.create!(:indicator => "weight", :value => "75.89" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 2.months) )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "healthy" ,:measured_at => Time.now )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "sick" ,:measured_at => (Time.now - 2.days) )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "healthy" ,:measured_at => (Time.now - 3.days) )
          # place the current animal in the default group with born_at
          ProductLocalization.create!(:container_id => place_v.id, :product_id => animal.id, :nature => :interior, :started_at => r.arrived_on, :stopped_at => r.departed_on, :arrival_cause => r.arrival_cause, :departure_cause => r.departure_cause)
          ProductMembership.create!(:member_id => animal.id, :group_id => group_v.id, :started_at => r.arrived_on, :stopped_at => r.departed_on )

          # case = GENISSE 1
        elsif r.born_on > (Date.today - 12.months) and r.born_on < (Date.today - 3.months) and r.sex == :female
          f = File.open(pictures.sample)
          animal = Animal.create!(:variant_id => cow_v.id, :name => r.name, :variety => "bos",
                                  :identification_number => r.identification_number, :work_number => r.work_number,
                                  :born_at => r.born_on, :dead_at => r.departed_on, :sex => r.sex,
                                  :picture => f, :owner_id => Entity.of_company.id, :reproductor => false
                                  )
          f.close
          # set default indicators
          animal.indicator_data.create!(:indicator => "weight", :value => "55.45" ,:measure_unit => "kilogram" ,:measured_at => r.born_on.to_datetime )
          animal.indicator_data.create!(:indicator => "weight", :value => "75.89" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 2.months) )
          animal.indicator_data.create!(:indicator => "weight", :value => "89.56" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 4.months) )
          animal.indicator_data.create!(:indicator => "weight", :value => "129.56" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 8.months) )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "healthy" ,:measured_at => Time.now )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "sick" ,:measured_at => (Time.now - 2.days) )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "healthy" ,:measured_at => (Time.now - 3.days) )
          # place the current animal in the default group with born_at
          ProductLocalization.create!(:container_id => place_gen.id, :product_id => animal.id, :nature => :interior, :started_at => r.arrived_on, :stopped_at => r.departed_on, :arrival_cause => r.arrival_cause, :departure_cause => r.departure_cause)
          ProductMembership.create!(:member_id => animal.id, :group_id => group_gen1.id, :started_at => r.arrived_on, :stopped_at => r.departed_on )

          # case = GENISSE 3
        elsif r.born_on > (Date.today - 28.months) and r.born_on < (Date.today - 12.months) and r.sex == :female
          f = File.open(pictures.sample)
          animal = Animal.create!(:variant_id => cow_v.id, :name => r.name, :variety => "bos",
                                  :identification_number => r.identification_number, :work_number => r.work_number,
                                  :born_at => r.born_on, :dead_at => r.departed_on, :sex => r.sex,
                                  :picture => f, :owner_id => Entity.of_company.id, :reproductor => true
                                  )
          f.close
          # set default indicators
          animal.indicator_data.create!(:indicator => "weight", :value => "55.45" ,:measure_unit => "kilogram" ,:measured_at => r.born_on.to_datetime )
          animal.indicator_data.create!(:indicator => "weight", :value => "75.89" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 2.months) )
          animal.indicator_data.create!(:indicator => "weight", :value => "89.56" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 4.months) )
          animal.indicator_data.create!(:indicator => "weight", :value => "129.56" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 8.months) )
          animal.indicator_data.create!(:indicator => "weight", :value => "159.56" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 12.months) )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "healthy" ,:measured_at => Time.now )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "sick" ,:measured_at => (Time.now - 2.days) )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "healthy" ,:measured_at => (Time.now - 3.days) )
          # place the current animal in the default group with born_at
          ProductLocalization.create!(:container_id => place_gen.id, :product_id => animal.id, :nature => :interior, :started_at => r.arrived_on, :stopped_at => r.departed_on, :arrival_cause => r.arrival_cause, :departure_cause => r.departure_cause)
          ProductMembership.create!(:member_id => animal.id, :group_id => group_gen3.id, :started_at => r.arrived_on, :stopped_at => r.departed_on )

          # case = VL
        elsif r.born_on > (Date.today - 20.years) and r.born_on < (Date.today - 28.months) and r.sex == :female
          f = File.open(pictures.sample)
          animal = Animal.create!(:variant_id => cow_vl.id, :name => r.name, :variety => "bos",
                                  :identification_number => r.identification_number, :work_number => r.work_number,
                                  :born_at => r.born_on, :dead_at => r.departed_on, :sex => r.sex,
                                  :picture => f, :owner_id => Entity.of_company.id, :reproductor => true
                                  )
          f.close
          # set default indicators
          animal.indicator_data.create!(:indicator => "weight", :value => "55.45" ,:measure_unit => "kilogram" ,:measured_at => r.born_on.to_datetime )
          animal.indicator_data.create!(:indicator => "weight", :value => "75.89" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 2.months) )
          animal.indicator_data.create!(:indicator => "weight", :value => "89.56" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 4.months) )
          animal.indicator_data.create!(:indicator => "weight", :value => "159.16" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 12.months) )
          animal.indicator_data.create!(:indicator => "weight", :value => "389.56" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 24.months) )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "healthy" ,:measured_at => Time.now )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "sick" ,:measured_at => (Time.now - 2.days) )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "healthy" ,:measured_at => (Time.now - 3.days) )
          # place the current animal in the default group with born_at
          ProductLocalization.create!(:container_id => place_vl.id, :product_id => animal.id, :nature => :interior, :started_at => r.arrived_on, :stopped_at => r.departed_on, :arrival_cause => r.arrival_cause, :departure_cause => r.departure_cause)
          ProductMembership.create!(:member_id => animal.id, :group_id => group_vl.id, :started_at => r.arrived_on, :stopped_at => r.departed_on )


          # case = TAURILLON
        elsif r.born_on > (Date.today - 10.years) and r.born_on < (Date.today - 3.months) and r.sex == :male
          f = File.open(photo_taur)
          animal = Animal.create!(:variant_id => cow_vl.id, :name => r.name, :variety => "bos",
                                  :identification_number => r.identification_number, :work_number => r.work_number,
                                  :born_at => r.born_on, :dead_at => r.departed_on, :sex => r.sex,
                                  :picture => f, :owner_id => Entity.of_company.id
                                  )
          f.close
          # set default indicators
          animal.indicator_data.create!(:indicator => "weight", :value => "55.45" ,:measure_unit => "kilogram" ,:measured_at => r.born_on.to_datetime )
          animal.indicator_data.create!(:indicator => "weight", :value => "75.89" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 2.months) )
          animal.indicator_data.create!(:indicator => "weight", :value => "89.56" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 4.months) )
          animal.indicator_data.create!(:indicator => "weight", :value => "259.16" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 12.months) )
          animal.indicator_data.create!(:indicator => "weight", :value => "389.56" ,:measure_unit => "kilogram" ,:measured_at => (r.born_on.to_datetime + 24.months) )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "healthy" ,:measured_at => Time.now )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "sick" ,:measured_at => (Time.now - 2.days) )
          animal.indicator_data.create!(:indicator => "animal_disease_state", :value => "healthy" ,:measured_at => (Time.now - 3.days) )
          # place the current animal in the default group with born_at
          ProductLocalization.create!(:container_id => place_taur.id, :product_id => animal.id, :nature => :interior, :started_at => r.arrived_on, :stopped_at => r.departed_on, :arrival_cause => r.arrival_cause, :departure_cause => r.departure_cause)
          ProductMembership.create!(:member_id => animal.id, :group_id => group_taur.id, :started_at => r.arrived_on, :stopped_at => r.departed_on )
        else print " "
        end

        print "."
        break if Animal.count >= max
      end
      puts "!"

      #add list of external male reproductor
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Animals - UPRA reproductor list: "
      file = Rails.root.join("test", "fixtures", "files", "liste_males_reproducteurs_race_normande_ISU_130.txt")
      picture_trepro = Dir.glob(Rails.root.join("test", "fixtures", "files", "animals", "taurillon.jpg"))
      CSV.foreach(file, :encoding => "CP1252", :col_sep => "\t", :headers => true) do |row|
        next if row[4].blank?
        r = OpenStruct.new(:order => row[0],
                           :name => row[1],
                           :identification_number => row[2],
                           :father => row[3],
                           :provider => row[4],
                           :isu => row[5],
                           :inel => row[9],
                           :tp => row[10],
                           :tb => row[11]
                           )
        # case = TAUREAU REPRO
        animal = Animal.create!(:variant_id => cow_trepro.id, :name => r.name, :variety => "bos", :identification_number => r.identification_number, :sex => "male", :reproductor => true, :external => true, :owner_id => Entity.of_company.id)
        # set default indicators
        animal.indicator_data.create!(:indicator => "isu", :value => r.isu ,:measure_unit => "unity" ,:measured_at => Time.now - 2.months )
        animal.indicator_data.create!(:indicator => "inel", :value => r.inel ,:measure_unit => "unity" ,:measured_at => Time.now - 2.months )
        animal.indicator_data.create!(:indicator => "tb", :value => r.tb ,:measure_unit => "unity" ,:measured_at => Time.now - 2.months )
        animal.indicator_data.create!(:indicator => "tp", :value => r.tp ,:measure_unit => "unity" ,:measured_at => Time.now - 2.months )

        print "."
        break if Animal.count >= max
      end


      # Assign parents
      Animal.find_each do |animal|
        animal.father = Animal.fathers.to_a.sample rescue nil
        animal.mother = Animal.mothers.where("born_at <= ?", (animal.born_at - 24.months)).to_a.sample rescue nil
        animal.save!
      end
      puts "!"


      #############################################################################
      # Import shapefile
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] LandParcelClusters - TelePAC Shapefile 2013 : "
      # v = ProductVariety.find_by_code("land_parcel")
      # p = ProductVariety.find_by_code("place")
      # v ||= ProductVariety.create!(:name => "Parcelle", :code => "land_parcel", :product_type => "LandParcel", :parent_id => (p ? p.id : nil))
      land_unit = "square_meter"
      land_parcel_product_nature_category = ProductNatureCategory.find_by_name("Ilôts")
      land_parcel_product_nature_category ||= ProductNatureCategory.create!(:name => "Ilôts", :published => true)
      land_parcel_group = ProductNature.find_by_number("LANDPARCELCLUSTER")
      land_parcel_group ||= ProductNature.create!(:name => "Ilôt", :number => "LANDPARCELCLUSTER", :variety => "land_parcel_cluster", :category_id => land_parcel_product_nature_category.id)
      land_parcel_group_variant = land_parcel_group.variants.create!(:active => true, :commercial_name => land_parcel_group.name, :name => land_parcel_group.name,
                                         :purchase_indicator => "net_surperficial_area", :purchase_indicator_unit => "hectare",
                                         :sale_indicator => "net_surperficial_area", :sale_indicator_unit => "hectare",
                                         :usage_indicator => "net_surperficial_area", :usage_indicator_unit => "hectare"
                                         )
      RGeo::Shapefile::Reader.open(Rails.root.join("test", "fixtures", "files", "ilot_017005218.shp").to_s, :srid => 2154) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          LandParcelCluster.create!(:variant_id => land_parcel_group_variant.id,
                                    :shape => record.geometry,
                                    :name => "ilôt "+record.attributes['NUMERO'].to_s,
                                    :work_number => record.attributes['NUMERO'].to_s,
                                    :variety => "land_parcel_cluster",
                                    :born_at => Date.civil(record.attributes['CAMPAGNE'], 1, 1),
                                    :owner_id => Entity.of_company.id,
                                    :identification_number => record.attributes['PACAGE'].to_s + record.attributes['CAMPAGNE'].to_s + record.attributes['NUMERO'].to_s)
          # puts "Record number #{record.index}:"
          # puts "  Geometry: #{record.geometry.as_text}"
          # puts "  Attributes: #{record.attributes.inspect}"
          print "."
        end
      end
      puts "!"

      #############################################################################
      # Import land_parcel from Calc Sheet
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] LandParcels - GAEC DUPONT Parcel sheet 2013 : "
      # v = ProductVariety.find_by_code("land_parcel")
      # p = ProductVariety.find_by_code("place")
      # v ||= ProductVariety.create!(:name => "Parcelle", :code => "land_parcel", :product_type => "LandParcel", :parent_id => (p ? p.id : nil))
      land_parcel_unit = "hectare"
      cultural_land_parcel_product_nature_category = ProductNatureCategory.find_by_name("Parcelles cultivables")
      cultural_land_parcel_product_nature_category ||= ProductNatureCategory.create!(:name => "Parcelles cultivables", :published => true)
      land_parcel_group_nature = ProductNature.find_by_number("LANDPARCELGROUP")
      land_parcel_group_nature ||= ProductNature.create!(:name => "Parcelle culturale", :number => "LANDPARCELGROUP", :variety => "land_parcel_group", :category_id => cultural_land_parcel_product_nature_category.id)
      land_parcel_group_nature_variant = land_parcel_group_nature.variants.create!(:active => true, :commercial_name => land_parcel_group_nature.name, :name => land_parcel_group_nature.name,
                                         :purchase_indicator => "net_surperficial_area", :purchase_indicator_unit => "hectare",
                                         :sale_indicator => "net_surperficial_area", :sale_indicator_unit => "hectare",
                                         :usage_indicator => "net_surperficial_area", :usage_indicator_unit => "hectare"
                                         )

      land_parcel_nature = ProductNature.find_by_number("LANDPARCEL")
      land_parcel_nature ||= ProductNature.create!(:name => "Parcelle", :number => "LANDPARCEL", :variety => "land_parcel", :category_id => cultural_land_parcel_product_nature_category.id)
      land_parcel_nature_variant = land_parcel_nature.variants.create!(:active => true, :commercial_name => land_parcel_nature.name, :name => land_parcel_nature.name,
                                         :purchase_indicator => "net_surperficial_area", :purchase_indicator_unit => "hectare",
                                         :sale_indicator => "net_surperficial_area", :sale_indicator_unit => "hectare",
                                         :usage_indicator => "net_surperficial_area", :usage_indicator_unit => "hectare"
                                         )

      # Load file
      file = Rails.root.join("test", "fixtures", "files", "parcelle_017005218.csv")
      CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
        r = OpenStruct.new(:ilot_work_number => row[0],
                           :campaign => row[1],
                           :land_parcel_group_work_number => row[2],
                           :land_parcel_group_name => row[3].capitalize,
                           :land_parcel_work_number => row[4],
                           :land_parcel_name => row[5].capitalize,
                           :land_parcel_area => row[6].to_d,
                           :land_parcel_group_shape => row[7],
                           :land_parcel_shape => row[8],
                           :land_parcel_plant_name => row[9],
                           :land_parcel_plant_variety => row[10]
                           )

        if land_parcel_cluster = LandParcelCluster.find_by_work_number(r.ilot_work_number)
          cultural_land_parcel = LandParcelGroup.find_by_work_number(r.land_parcel_group_work_number)
          cultural_land_parcel ||= LandParcelGroup.create!(:variant_id => land_parcel_group_nature_variant.id,
                                                           :shape => r.land_parcel_group_shape,
                                                           :name => r.land_parcel_group_name,
                                                           :work_number => r.land_parcel_group_work_number,
                                                           :variety => "land_parcel_group",
                                                           :born_at => Time.now,
                                                           :owner_id => Entity.of_company.id,
                                                           :identification_number => r.land_parcel_group_work_number)

          land_parcel = LandParcel.find_by_work_number(r.land_parcel_work_number)
          land_parcel ||= LandParcel.create!(:variant_id => land_parcel_nature_variant.id,
                                             :shape => r.land_parcel_shape,
                                             #:real_quantity =>r.land_parcel_area, (waiting for indicators)
                                             :name => r.land_parcel_name,
                                             :work_number => r.land_parcel_work_number,
                                             :variety => "land_parcel",
                                             :born_at => Time.now,
                                             :owner_id => Entity.of_company.id,
                                             :identification_number => r.land_parcel_work_number)

          land_parcel_cluster.add(land_parcel)
          cultural_land_parcel.add(land_parcel)

        end

        # puts "Record number #{record.index}:"
        # puts "  Geometry: #{record.geometry.as_text}"
        # puts "  Attributes: #{record.attributes.inspect}"
        print "."
        #break if LandParcelGroup.count >= max
      end
      puts "!"

      # # add shape to land_parcel
      # RGeo::Shapefile::Reader.open(Rails.root.join("test", "fixtures", "files", "parcelle_017005218.shp").to_s, :srid => 2154) do |file|
      # # puts "File contains #{file.num_records} records."
      # file.each do |record|
      # lp = LandParcel.find_by_work_number(record.attributes['NUMERO'].to_s)
      # if lp.present?
      # lp.update_attributes!(:shape => record.geometry)
      # end
      # # puts "Record number #{record.index}:"
      # # puts "  Geometry: #{record.geometry.as_text}"
      # # puts "  Attributes: #{record.attributes.inspect}"
      # print "."
      # end
      # end
      # puts "!"

      #############################################################################
      # Create variety for wheat product
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Sales - Examples Data : "
      price_listing = ProductPriceListing.find_by_code("STD")
      wheat_category = ProductNatureCategory.find_by_name("Produits végétaux")
      wheat_category ||= ProductNatureCategory.create!(:name => "Produits végétaux")
      grain_unit = "quintal"
      sole_unit = "hectare"
      wheat_charge_account = Account.find_by_number("601")
      wheat_product_account = Account.find_by_number("701")
      wheat_stock_account = Account.find_in_chart(:plant_derivative_stock)
      wheat_price_template_tax = Tax.find_by_amount(5.5)

      # Create product_nature for grain plant product
      for attributes in [{:individual => false, :name => "Grain de Blé", :number => "GRAIN_BLE", :variety => "grains", :saleable => true, :purchasable => true},
                         {:individual => false, :name => "Grain d'Orge", :number => "GRAIN_ORGE", :variety => "grains", :saleable => true, :purchasable => true},
                         {:individual => false, :name => "Grain de Maïs", :number => "GRAIN_MAIS", :variety => "grains", :saleable => true, :purchasable => true},
                         {:individual => false, :name => "Grain de Blé dur", :number => "GRAIN_BLE_DUR", :variety => "grains", :saleable => true, :purchasable => true},
                         {:individual => false, :name => "Grain de Triticale", :number => "GRAIN_TRITICALE", :variety => "grains", :saleable => true, :purchasable => true},
                         {:individual => false, :name => "Grain de Tournesol", :number => "GRAIN_TOURNESOL", :variety => "grains", :saleable => true, :purchasable => true}
                        ]
        unless ProductNature.find_by_number(attributes[:number])
          plant_product_nature_g = ProductNature.create!({:active => true, :category_id => wheat_category.id,
                                                        :storable => true, :derivative_of => "plant",
                                                        :stock_account_id => wheat_stock_account.id,
                                                        :charge_account_id => wheat_charge_account.id,
                                                        :product_account_id => wheat_product_account.id}.merge(attributes))
          plant_product_nature_g.variants.create!(:active => true, :commercial_name => plant_product_nature_g.name, :name => plant_product_nature_g.name,
                                         :purchase_indicator => "net_weight", :purchase_indicator_unit => "quintal",
                                         :sale_indicator => "net_weight", :sale_indicator_unit => "quintal",
                                         :usage_indicator => "net_weight", :usage_indicator_unit => "kilogram"
                                         )
        end
      end
      
            # Create product_nature for plant product
      for attributes in [
                         {:individual => true, :name => "Sole de Blé",  :number => "SOLE_BLE"},
                         {:individual => true, :name => "Sole d'Orge",  :number => "SOLE_ORGE"},
                         {:individual => true, :name => "Sole de Maïs", :number => "SOLE_MAIS"},
                         {:individual => true, :name => "Sole de Blé dur",  :number => "SOLE_BLE_DUR"},
                         {:individual => true, :name => "Sole de Jachère annuelle",  :number => "SOLE_JACHERE_AN"},
                         {:individual => true,  :name => "Sole de Triticale", :number => "SOLE_TRITICALE"},
                         {:individual => true, :name => "Sole de Tournesol", :number => "SOLE_TOURNESOL"},
                         {:individual => true, :name => "Sole de Sorgho", :number => "SOLE_SORGHO"},
                         {:individual => true, :name => "Sole de Prairie", :number => "SOLE_PRAIRIE"}
                        ]
        unless ProductNature.find_by_number(attributes[:number])
          plant_product_nature_s = ProductNature.create!({:active => true, :category_id => wheat_category.id,
                                                        :storable => true,:variety => "plant",
                                                        :stock_account_id => wheat_stock_account.id,
                                                        :charge_account_id => wheat_charge_account.id,
                                                        :product_account_id => wheat_product_account.id}.merge(attributes))
          plant_product_nature_s.variants.create!(:active => true, :commercial_name => plant_product_nature_s.name, :name => plant_product_nature_s.name,
                                         :purchase_indicator => "net_surperficial_area", :purchase_indicator_unit => "hectare",
                                         :sale_indicator => "net_surperficial_area", :sale_indicator_unit => "hectare",
                                         :usage_indicator => "net_surperficial_area", :usage_indicator_unit => "hectare"
                                         )
        end
      end
      
      # Create product_nature for raw plant product
      for attributes in [
                         {:individual => false, :name => "Paille de Blé", :number => "PAILLE_BLE", :variety => "stem", :saleable => true, :purchasable => true},
                         {:individual => false, :name => "Paille d'Orge", :number => "PAILLE_ORGE", :variety => "stem", :saleable => true, :purchasable => true},
                         {:individual => false, :name => "Paille de Blé dur",  :number => "PAILLE_BLE_DUR", :variety => "stem", :saleable => true, :purchasable => true},
                         {:individual => false, :name => "Paille de Triticale", :number => "PAILLE_TRITICALE", :variety => "stem", :saleable => true, :purchasable => true},
                         {:individual => false, :name => "Herbe sur pied de Prairie", :number => "HERBE_PRAIRIE", :variety => "stem", :saleable => false, :purchasable => false},
                         {:individual => false, :name => "Foin de Prairie", :number => "FOIN_PRAIRIE", :variety => "stem", :saleable => true, :purchasable => true},
                         {:individual => false, :name => "Ensilage de Sorgho", :number => "ENSILAGE_SORGHO", :variety => "stem", :saleable => false, :purchasable => false},
                         {:individual => false, :name => "Ensilage de Maïs", :number => "ENSILAGE_MAIS", :variety => "stem", :saleable => false, :purchasable => false},
                         {:individual => false, :name => "Ensilage de Prairie", :number => "ENSILAGE_PRAIRIE", :variety => "stem", :saleable => false, :purchasable => false}
                        ]
        unless ProductNature.find_by_number(attributes[:number])
          plant_product_nature_p = ProductNature.create!({:active => true, :category_id => wheat_category.id,
                                                        :storable => true, :derivative_of => "plant",
                                                        :stock_account_id => wheat_stock_account.id,
                                                        :charge_account_id => wheat_charge_account.id,
                                                        :product_account_id => wheat_product_account.id}.merge(attributes))
          plant_product_nature_p.variants.create!(:active => true, :commercial_name => plant_product_nature_p.name, :name => plant_product_nature_p.name,
                                         :purchase_indicator => "net_weight", :purchase_indicator_unit => "ton",
                                         :sale_indicator => "net_weight", :sale_indicator_unit => "ton",
                                         :usage_indicator => "net_weight", :usage_indicator_unit => "kilogram"
                                         )
        end
      end
      
      
      

      # Create product_nature_price for wheat product
      #wheat_price_template   = ProductPriceTemplate.find_by_product_nature_id(wheat.id)
      #wheat_price_template ||= ProductPriceTemplate.create!(:assignment_amount => 211, :currency => "EUR", :assignment_pretax_amount => 200, :product_nature_id => wheat.id, :tax_id => wheat_price_template_tax.id, :listing_id => price_listing.id, :supplier_id => Entity.of_company.id )
      # Create wheat product
      wheat = ProductNatureVariant.find_by_nature_name("Grain de Blé")

      ble = OrganicMatter.find_by_work_number("BLE_001")
      ble = OrganicMatter.create!(:variant_id => wheat.id, :name => "Blé Cap Horn 2011", :variety => "organic_matter", :identification_number => "BLE_2011_07142011", :work_number => "BLE_2011",
                                  :born_at => "2011-07-14", :owner_id => Entity.of_company.id) #

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
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] IncomingDeliveries - Charentes Alliance Coop Order (Appro) 2013 : "

       # create product_nature for organic matters and others usefull for coop

      price_listing = ProductPriceListing.find_by_code("STD")
      phyto_category = ProductNatureCategory.find_by_name("Produits phytosanitaires")
      phyto_category ||= ProductNatureCategory.create!(:name => "Produits phytosanitaires")
      fertilizer_category = ProductNatureCategory.find_by_name("Produits fertilisants")
      fertilizer_category ||= ProductNatureCategory.create!(:name => "Produits fertilisants")
      seed_category = ProductNatureCategory.find_by_name("Semences")
      seed_category ||= ProductNatureCategory.create!(:name => "Semences")
      livestock_feed_category = ProductNatureCategory.find_by_name("Aliments")
      livestock_feed_category ||= ProductNatureCategory.create!(:name => "Aliments")
      other_consumable_category = ProductNatureCategory.find_by_name("Quincaillerie")
      other_consumable_category ||= ProductNatureCategory.create!(:name => "Quincaillerie")

      # charge account for product nature
      fertilizer_charge_account = Account.find_in_chart(:fertilizer_charge)
      seed_charge_account = Account.find_in_chart(:seed_charge)
      plant_medicine_matter_charge_account = Account.find_in_chart(:plant_medicine_matter_charge)
      livestock_feed_matter_charge_account = Account.find_in_chart(:livestock_feed_matter_charge)
      animal_medicine_matter_charge_account = Account.find_in_chart(:animal_medicine_matter_charge)
      other_consumable_matter_charge_account = Account.find_in_chart(:other_consumable_matter_charge)

      # stock account for product nature
      fertilizer_stock_account = Account.find_in_chart(:fertilizer_stock)
      seed_stock_account = Account.find_in_chart(:seed_stock)
      plant_medicine_matter_stock_account = Account.find_in_chart(:plant_medicine_matter_stock)
      livestock_feed_matter_stock_account = Account.find_in_chart(:livestock_feed_matter_stock)
      animal_medicine_matter_stock_account = Account.find_in_chart(:animal_medicine_matter_stock)
      other_consumable_matter_stock_account = Account.find_in_chart(:other_consumable_matter_stock)
      appro_price_template_tax = Tax.find_by_amount(5.5)

      # Create product_nature for plant product
      for attributes in [{:name => "Herbicide", :number => "HERBICIDE",
                          :category_id => phyto_category.id,
                          :individual => false, :variety => "plant_medicine",
                          :purchasable => true, :charge_account_id => plant_medicine_matter_charge_account.id,
                          :storable => true, :stock_account_id => plant_medicine_matter_stock_account.id
                          },
                          {:name => "Fongicide", :number => "FONGICIDE",
                          :category_id => phyto_category.id,
                          :individual => false, :variety => "plant_medicine",
                          :purchasable => true, :charge_account_id => plant_medicine_matter_charge_account.id,
                          :storable => true, :stock_account_id => plant_medicine_matter_stock_account.id
                          },
                          {:name => "Anti-limace", :number => "ANTI_LIMACE",
                          :category_id => phyto_category.id,
                          :individual => false, :variety => "plant_medicine",
                          :purchasable => true, :charge_account_id => plant_medicine_matter_charge_account.id,
                          :storable => true, :stock_account_id => plant_medicine_matter_stock_account.id
                          },
                          {:name => "Engrais", :number => "ENGRAIS",
                          :category_id => fertilizer_category.id,
                          :individual => false, :variety => "mineral_matter",
                          :purchasable => true, :charge_account_id => fertilizer_charge_account.id,
                          :storable => true, :stock_account_id => fertilizer_stock_account.id
                          },
                          {:name => "Semence", :number => "SEMENCE",
                          :category_id => seed_category.id,
                          :individual => false, :variety => "seed", :derivative_of => "plant",
                          :purchasable => true, :charge_account_id => seed_charge_account.id,
                          :storable => true, :stock_account_id => seed_stock_account.id
                          },
                          {:name => "Aliment", :number => "ALIMENT",
                          :category_id => livestock_feed_category.id,
                          :individual => false, :variety => "plant_food", :derivative_of => "plant",
                          :purchasable => true, :charge_account_id => livestock_feed_matter_charge_account.id,
                          :storable => true, :stock_account_id => livestock_feed_matter_stock_account.id
                          },
                          {:name => "Quincaillerie", :number => "QUINCAILLERIE",
                          :category_id => other_consumable_category.id,
                          :individual => false, :variety => "equipment",
                          :purchasable => true, :charge_account_id => other_consumable_matter_charge_account.id,
                          :storable => true, :stock_account_id => other_consumable_matter_stock_account.id
                          },
                          {:name => "Location Matériel", :number => "LOCATION_MATERIEL",
                          :category_id => other_consumable_category.id,
                          :individual => false, :variety => "equipment",
                          :purchasable => true, :charge_account_id => other_consumable_matter_charge_account.id,
                          :storable => false, :stock_account_id => other_consumable_matter_stock_account.id
                          },
                          {:name => "Nettoyant", :number => "NETTOYANT",
                          :category_id => other_consumable_category.id,
                          :individual => false, :variety => "mineral_matter",
                          :purchasable => true, :charge_account_id => other_consumable_matter_charge_account.id,
                          :storable => true, :stock_account_id => other_consumable_matter_stock_account.id
                          },
                          {:name => "Petit Equipement", :number => "PETIT_EQUIPEMENT",
                          :category_id => other_consumable_category.id,
                          :individual => false, :variety => "equipment",
                          :purchasable => true, :charge_account_id => other_consumable_matter_charge_account.id,
                          :storable => true, :stock_account_id => other_consumable_matter_stock_account.id
                          }
                         ]
        unless ProductNature.find_by_number(attributes[:number])
          ProductNature.create!({:active => true}.merge(attributes) )
        end
      end
      
      for attributes in [
                         {:number => "HERBICIDE",:pi => "net_volume", :piu => "liter", :si => "net_volume", :siu => "liter", :ui => "net_volume", :uiu => "liter"},
                         {:number => "FONGICIDE",:pi => "net_volume", :piu => "liter", :si => "net_volume", :siu => "liter", :ui => "net_volume", :uiu => "liter"},
                         {:number => "ANTI_LIMACE",:pi => "net_weight", :piu => "kilogram", :si => "net_weight", :siu => "kilogram", :ui => "net_weight", :uiu => "kilogram"},
                         {:number => "ENGRAIS",:pi => "net_weight", :piu => "ton", :si => "net_weight", :siu => "ton", :ui => "net_weight", :uiu => "kilogram"},
                         {:number => "SEMENCE",:pi => "net_weight", :piu => "kilogram", :si => "net_weight", :siu => "kilogram", :ui => "net_weight", :uiu => "kilogram"},
                         {:number => "ALIMENT",:pi => "net_weight", :piu => "ton", :si => "net_weight", :siu => "ton", :ui => "net_weight", :uiu => "kilogram"},
                         {:number => "QUINCAILLERIE",:pi => "population", :piu => "unity", :si => "population", :siu => "unity", :ui => "population", :uiu => "unity"},
                         {:number => "NETTOYANT",:pi => "net_volume", :piu => "liter", :si => "net_volume", :siu => "liter", :ui => "net_volume", :uiu => "liter"},
                         {:number => "LOCATION_MATERIEL",:pi => "usage_duration", :piu => "hour", :si => "usage_duration", :siu => "hour", :ui => "usage_duration", :uiu => "hour"},
                         {:number => "PETIT_EQUIPEMENT",:pi => "population", :piu => "unity", :si => "population", :siu => "unity", :ui => "population", :uiu => "unity"}
                        ]
                          
       if pn = ProductNature.find_by_number(attributes[:number])
         pn.variants.create!(
                             :active => true, 
                             :commercial_name => pn.name, :name => pn.name,
                             :purchase_indicator => attributes[:pi], :purchase_indicator_unit => attributes[:piu],
                             :sale_indicator => attributes[:si], :sale_indicator_unit => attributes[:siu],
                             :usage_indicator => attributes[:ui], :usage_indicator_unit => attributes[:uiu]
                            )
       end
      end

      suppliers = Entity.where(:of_company => false, :supplier => true).reorder(:supplier_account_id, :last_name) # .where(" IS NOT NULL")
      coop = suppliers.offset((suppliers.count/2).floor).first

      # add Coop incoming deliveries

      # status to map
      status = {
        "Liquidé" => :order,
        "A livrer" => :estimate,
        "Supprimé" => :aborted
      }

      pnature = {
        "Maïs classe a" => "SEMENCE",
        "Graminées fourragères" => "SEMENCE",
        "Légumineuses fourragères" => "SEMENCE",
        "Divers" => "SEMENCE",
        "Blé tendre" => "SEMENCE",
        "Blé dur" => "SEMENCE",
        "Orge hiver escourgeon" => "SEMENCE",
        "Couverts environnementaux enherbeme" => "SEMENCE",

        "Engrais" => "ENGRAIS",

        "Fongicides céréales" => "FONGICIDE",
        "Fongicides colza" => "FONGICIDE",
        "Herbicides maïs" => "HERBICIDE",
        "Herbicides totaux" => "HERBICIDE",
        "Adjuvants" => "HERBICIDE",
        "Herbicides autres" => "HERBICIDE",
        "Herbicides céréales et fouragères" => "HERBICIDE",

        "Céréales"  => "ALIMENT",
        "Chevaux" => "ALIMENT",
        "Compléments nutritionnels" => "ALIMENT",
        "Minéraux sel blocs" => "ALIMENT",

        "Anti-limaces" => "ANTI_LIMACE",

        "Location semoir" => "LOCATION_MATERIEL",

        "Nettoyants" => "NETTOYANT",

        "Films plastiques" => "QUINCAILLERIE",
        "Recyclage" => "QUINCAILLERIE",
        "Ficelles" => "QUINCAILLERIE"
      }

        file = Rails.root.join("test", "fixtures", "files", "coop-appro.csv")
        CSV.foreach(file, :encoding => "UTF-8", :col_sep => ";", :headers => true) do |row|
        r = OpenStruct.new(:order_number => row[0],
                           :ordered_on => Date.civil(*row[1].to_s.split(/\//).reverse.map(&:to_i)),
                           :product_nature_category => ProductNatureCategory.find_by_name(row[2]) || ProductNatureCategory.create!(:catalog_name => row[2], :name => row[2], :published => true ) ,
                           :product_nature_name => (pnature[row[3]] || "QUINCAILLERIE"),
                           :matter_name => row[4],
                           :quantity => row[5].to_d,
                           :product_deliver_quantity => row[6].to_d,
                           :product_unit_price => row[7].to_d,
                           :order_status => (status[row[8]] || :draft)
                           )
      # create an incoming deliveries if not exist and status = 2
      if r.order_status == :order
        order = IncomingDelivery.find_by_reference_number(r.order_number)
        order ||= IncomingDelivery.create!(:reference_number => r.order_number, :planned_at => r.ordered_on, :sender_id => coop.id, :address_id => "1")
        # find a product_nature by mapping current sub_family of coop file
        product_nature = ProductNature.find_by_number(r.product_nature_name)
        product_nature_variant = ProductNatureVariant.find_by_nature_id(product_nature.id)
        product_model = product_nature.matching_model
        incoming_item = Product.find_by_name_and_created_at(r.matter_name,r.ordered_on)
        incoming_item ||= product_model.create!(:owner_id => Entity.of_company.id, :name => r.matter_name, :variant_id => product_nature_variant.id, :born_at => r.ordered_on, :created_at => r.ordered_on)
        incoming_item.indicator_data.create!(:indicator => product_nature_variant.purchase_indicator, :value => r.quantity,
                                        :measure_unit => product_nature_variant.purchase_indicator_unit,
                                        :measured_at => Time.now
                                        )
        if product_nature.present? and incoming_item.present?
          order.items.create!(:product_id => incoming_item.id, :quantity => r.product_deliver_quantity)
        end
      end
      # purchase   = Purchase.find_by_reference_number(r.order_number)
      # purchase ||= Purchase.create!(:state => r.order_status, :currency => "EUR", :nature_id => purchase_nature.id, :reference_number => r.order_number, :supplier_id => coop.id, :planned_on => r.ordered_on, :created_on => r.ordered_on)
      # tax_price_nature_appro = Tax.find_by_amount(19.6)
      # # create a product_nature if not exist
      # product_nature   = ProductNature.find_by_name(r.product_nature_name)
      # product_nature ||= ProductNature.create!(:stock_account_id => stock_account_nature_coop.id, :charge_account_id => charge_account_nature_coop.id, :name => r.product_nature_name, :saleable => false, :purchasable => true, :active => true, :storable => true, :variety => "building", :unit => "unity", :category_id => r.product_nature_category.id)
      # # create a product (Matter) if not exist
      # product   = Matter.find_by_name(r.matter_name)
      # product ||= Matter.create!(:name => r.matter_name, :identification_number => r.matter_name, :work_number => r.matter_name, :born_at => Time.now, :nature_id => product_nature.id, :owner_id => Entity.of_company.id, :number => r.matter_name) #
      # # create a product_price_template if not exist
      # product_price   = ProductPriceTemplate.find_by_product_nature_id_and_supplier_id_and_assignment_pretax_amount(product_nature.id, coop.id, r.product_unit_price)
      # product_price ||= ProductPriceTemplate.create!(:currency => "EUR", :assignment_pretax_amount => r.product_unit_price, :product_nature_id => product_nature.id, :tax_id => tax_price_nature_appro.id, :supplier_id => coop.id)
      # # create a purchase_item if not exist
      # # purchase_item   = PurchaseItem.find_by_product_id_and_purchase_id_and_price_id(product.id, purchase.id, product_price.id)
      # # purchase_item ||= PurchaseItem.create!(:quantity => r.quantity, :unit_id => unit_u.id, :price_id => product_price.id, :product_id => product.id, :purchase_id => purchase.id)
      # # puts "Default PPT: " + ProductPriceTemplate.by_default.class.name # (coop.id, product.nature_id).inspect
      # purchase.items.create!(:quantity => r.quantity, :product_id => product.id) unless r.quantity.zero?
      # # create an incoming_delivery if status => 2

      # create an incoming_delivery_item if status => 2


      print "."
      end

      puts "!"




      # #############################################################################
      # # import Coop Deliveries to make automatic sales
      # # @TODO finish with two level (sales and sales_lines)
      # @TODO make some correction for act_as_numbered
      # # set the coop
      # print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] OutgoingDelivery - Charentes Alliance Coop Delivery (Apport) 2013 : "
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
      print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Indicators - LILCO Milk analysis 2013 :"
      # set the product if not exist
      milk_unit = "liter"
      # @TODO = appeller la méthode des comptes comme dans la nomenclature accounts
      stock_account_nature_milk = Account.find_by_number("321")
      sale_account_nature_milk = Account.find_by_number("701")
      # variety_milk = ProductVariety.find_by_code("normande")
      # add a product_nature
      product_nature   = ProductNature.find_by_number("LAIT")
      product_nature ||= ProductNature.create!(:stock_account_id => stock_account_nature_milk.id, 
                                               :product_account_id => sale_account_nature_milk.id,
                                               :name => "lait",
                                               :number => "LAIT",
                                               :saleable => true,
                                               :purchasable => false,
                                               :active => true,
                                               :storable => true,
                                               :variety => "milk",
                                               :derivative_of => "bos",
                                               :indicators => "total_bacteria_concentration, inhibitors_presence, fat_matters_concentration, protein_matters_concentration, cells_concentration, clostridial_spores_concentration, freezing_point_temperature, lipolysis, immunoglobulins_concentration, urea_concentration",
                                               :category_id => animal_product_nature_category.id
                                               )
      product_nature_variant = product_nature.variants.create!(
                             :active => true, 
                             :commercial_name => product_nature.name, :name => product_nature.name,
                             :purchase_indicator => "net_volume", :purchase_indicator_unit => milk_unit,
                             :sale_indicator => "net_volume", :sale_indicator_unit => milk_unit,
                             :usage_indicator => "net_volume", :usage_indicator_unit => milk_unit
                            )

      # create a generic product to link analysis_indicator
      product   = Matter.find_by_name("lait_vache")
      product ||= Matter.create!(:name => "lait_vache", :identification_number => "MILK_FR_2010-2013", :work_number => "lait_2013", :born_at => Time.now, :variant_id => product_nature_variant.id, :owner_id => Entity.of_company.id, :number => "L2011-2013") #

      trans_inhib = {
        "NEG" => "negative",
        "POS" => "positive"
      }

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
      file = Rails.root.join("test", "fixtures", "files", "activities_ref_demo_1.csv")
      CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
        r = OpenStruct.new(:description => row[0],
                           :name => row[1].downcase.capitalize,
                           :family => (families[row[2]] || :none).to_s,
                           :product_nature_name => row[3],
                           :nature => (natures[row[4]] || :none).to_s,
                           :campaign_name => row[5].blank? ? nil : row[5].to_s,
                           :work_number_land_parcel_storage => row[6].blank? ? nil : row[6].to_s
                           )
        land_parcel_support = LandParcelGroup.find_by_work_number(r.work_number_land_parcel_storage)
        # Create a campaign if not exist
        if r.campaign_name.present?
          campaign = Campaign.find_by_name(r.campaign_name)
          campaign ||= Campaign.create!(:name => r.campaign_name, :closed => false)
        end
        # Create an activity if not exist
        activity   = Activity.find_by_description(r.description)
        activity ||= Activity.create!(:nature => r.nature, :description => "Import from reference", :family => r.family, :name => r.name, :description => r.description)
        product_nature_sup = ProductNature.find_by_number(r.product_nature_name)
        if product_nature_sup.present?
          product_nature_variant_sup = ProductNatureVariant.find_by_nature_id(product_nature_sup.id)
        end
        if product_nature_variant_sup and land_parcel_support.present?
          pro = Production.where(:campaign_id => campaign.id,:activity_id => activity.id, :product_nature_id => product_nature_sup.id).first
          pro ||= activity.productions.create!(:product_nature_id => product_nature_sup.id, :campaign_id => campaign.id, :static_support => true)
          pro.supports.create!(:storage_id => land_parcel_support.id)
          plant_work_nb = (r.product_nature_name + "-" + campaign.name + "-" + land_parcel_support.work_number)
          Plant.create!(:variant_id => product_nature_variant_sup.id, :work_number => plant_work_nb , :name => (r.product_nature_name + " " + campaign.name + " " + land_parcel_support.name)  ,:variety => product_nature.variety, :born_at => Time.now, :owner_id => Entity.of_company.id)
        elsif product_nature_variant_sup
          pro = Production.where(:campaign_id => campaign.id, :activity_id => activity.id, :product_nature_id => product_nature_sup.id).first
          pro ||= activity.productions.create!(:product_nature_id => product_nature_sup.id, :campaign_id => campaign.id)
        end
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


       ##############################################################################
       ## Demo data for fertilizing
       ##############################################################################

       print "[#{(Time.now - start).round(2).to_s.rjust(8)}s] Procedures - demo data for fertilization reporting 2013 :"
       fertilizer_product_nature_variant = ProductNatureVariant.find_by_nature_name("Engrais")
       campaign = Campaign.find_by_name("2013")
       sole_ble_nature = ProductNature.find_by_number("SOLE_BLE")
       
       # create some indicator nature for fertilization
       # find some product for fertilization
       fertilizer_product = Product.find_by_variant_id(fertilizer_product_nature_variant.id)
       fertilizer_product_prev = Product.where("name LIKE 'AMMO%'").first
       # set indicator on product for fertilization
       for attributes in [{:indicator => "nitrogen_concentration", :value => "27.00"},
                          {:indicator => "potassium_concentration", :value => "33.30"},
                          {:indicator => "phosphorus_concentration", :value => "33.30"}
                            ]

       fertilizer_product.indicator_data.create!({:measure_unit => "kilograms_per_hectogram", :measured_at => Time.now }.merge(attributes))
       fertilizer_product_prev.indicator_data.create!({:measure_unit => "kilograms_per_hectogram", :measured_at => Time.now }.merge(attributes))

       end

       production = Production.find_by_product_nature_id_and_campaign_id(sole_ble_nature.id,campaign.id)

       procedure = Procedure.find_by_production_id_and_nomen(production.id,"organic_fertilizing")
       procedure ||= Procedure.create!(:nomen =>"organic_fertilizing", :production_id => production.id )


      Plant.find_each do |plant|
        # Create some procedure variable for fertilization
        for attributes in [{:nomen => "organic_fertilization", :target_id => plant.id, :roles => "target",
                            :procedure_indicator => "net_surperficial_area",
                            :procedure_quantity => "5.00", :procedure_unit => "hectare"},
                            {:nomen => "organic_fertilization", :target_id => fertilizer_product.id, :roles => "input",
                             :procedure_indicator => "net_weight",
                             :procedure_quantity => "5.00", :procedure_unit => "ton"},
                            {:nomen => "organic_fertilization", :target_id => fertilizer_product.id, :roles => "input",
                             :procedure_indicator => "net_weight",
                             :procedure_quantity => "575.00", :procedure_unit => "kilogram"},
                            {:nomen => "organic_fertilization", :target_id => plant.id, :roles => "prev_target",
                             :procedure_indicator => "net_surperficial_area",
                             :procedure_quantity => "3.00", :procedure_unit => "hectare"},
                            {:nomen => "organic_fertilization", :target_id => fertilizer_product_prev.id, :roles => "prev_input",
                             :procedure_indicator => "net_weight",
                             :procedure_quantity => "450.00", :procedure_unit => "kilogram"}
                           ]
         ProcedureVariable.create!({:procedure_id => procedure.id}.merge(attributes) )
        end

        # Create some operation variable for fertilization
        for attributes in [{:started_at => (Time.now - 2.days), :stopped_at => Time.now}]
         procedure.operations.create!({:procedure_id => procedure.id}.merge(attributes) )
        end
      end


      puts "Total time: #{(Time.now - start).round(2)}s"
    end
  end
end
