# -*- coding: utf-8 -*-
demo :equipments do


  Ekylibre::fixturize :equipments do |w|
  #############################################################################
  
  file = Rails.root.join("test", "fixtures", "files", "equipments_list.csv")
    CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
      r = OpenStruct.new(:name => row[0].blank? ? nil : row[0].to_s,
                         :nature_nomen => row[1].downcase.to_sym,
                         :variant => row[2].blank? ? nil : row[2],
                         :born_at => row[3].blank? ? nil : row[3],
                         :brand => row[4].blank? ? nil : row[4].to_s,
                         :model => row[5].blank? ? nil : row[5].to_s,
                         :external => row[6].blank? ? false : true ,
                         :indicators => row[7].blank? ? {} : row[7].to_s.delete(' ').downcase.split(';').collect{|i| i.split(':')},
                         #.inject({|h,i| h[i.first.strip.downcase.to_sym]=i.second; h}),
                         :owner => row[8].blank? ? Entity.of_company : LegalEntity.where(:last_name => row[8].to_s).first_or_create,
                         :notes => row[9].blank? ? nil : row[9].to_s
                         )
    
      product_nature = ProductNature.find_by(:nomen => r.nature_nomen) || ProductNature.import_from_nomenclature(r.nature_nomen)
      variant = product_nature.default_variant
      equipment = Equipment.create!(:variant_id => variant.id, :active => true, :external => r.external, 
                                    :name => r.name, :born_at => r.born_at, :owner_id => r.owner.id )
      
      h_indicators = r.indicators.inject({}) do |k, v|
        k.merge!({v[0].to_sym => v[1]})
      end
      
      puts h_indicators                                       
      #for indicator, value in h_indicators
      #  equipment.is_measured!(indicator, value)
      #end                                    
                                    
    w.check_point
    end


  end

end
