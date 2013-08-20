# -*- coding: utf-8 -*-
demo :general_ledger do

  Ekylibre::fixturize :general_ledger do |w|
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

      w.check_point
      # break if Entity.count >= max
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
  end

end
