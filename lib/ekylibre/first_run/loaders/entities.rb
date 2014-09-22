# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :entities do |first_run|

  file = first_run.path("alamano", "entities.csv")
  if file.exist?
    first_run.count :associates do |w|

      CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", headers: true) do |row|
        r = OpenStruct.new(:first_name => row[0].blank? ? "" : row[0].to_s,
                           :last_name => row[1].blank? ? "" : row[1].to_s,
                           :nature => row[2].to_s.downcase,
                           :client_account_number => row[3].to_s,
                           :supplier_account_number => row[4].to_s,
                           :usages => row[5].to_s,
                           :address => row[6].to_s,
                           :postal_code => row[7].blank? ? nil : row[7].to_s,
                           :town => row[8].blank? ? nil : row[8].to_s,
                           :phone_number => row[9].blank? ? nil : row[9].to_s,
                           :link_nature => row[10].blank? ? :undefined : row[10].to_sym,
                           :origin => (row[0].to_s + " " + row[1].to_s),
                           :file_code_prefix => row[11].blank? ? nil : row[11].to_s.downcase
                           )

        klass = r.nature.camelcase.constantize
        unless person = klass.find_by_meeting_origin(r.origin)
          person = klass.create!(
                                 :first_name => r.first_name,
                                 :last_name => r.last_name,
                                 :nature => r.nature,
                                 :client => true,
                                 :client_account_id => Account.get(r.client_account_number, :name => r.origin),
                                 :meeting_origin => r.origin,
                                 :supplier => true,
                                 :supplier_account_id => Account.get(r.supplier_account_number, :name => r.origin)
                                 )
          if !r.postal_code.nil? and !r.town.nil?
            person.addresses.create!(:canal => :mail, :mail_line_4 => r.address, :mail_line_6 => r.postal_code + " " + r.town, :mail_country => "fr")
          end
          if !r.phone_number.nil?
            person.addresses.create!(:canal => :phone, :coordinate => r.phone_number)
          end
          # update account name
          associate_account = Account.find_by_number(r.client_account_number)
          associate_account.name = r.origin
          associate_account.usages = r.usages
          associate_account.save!
        end
        if r.link_nature
          person.is_linked_to!(Entity.of_company, as: r.link_nature)
        end
        if r.file_code_prefix and picture = first_run.path("alamano", "entities_pictures", r.file_code_prefix + ".gif")
          f = File.open(picture) rescue nil
          person.picture = f
          person.save!
          f.close unless f.nil?
        end
        w.check_point
      end
    end
  end

end
