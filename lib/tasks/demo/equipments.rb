# -*- coding: utf-8 -*-
demo :equipments do


  Ekylibre::fixturize :equipments do |w|
  #############################################################################
  
  file = Rails.root.join("test", "fixtures", "files", "equipments_list.csv")
    CSV.foreach(file, :encoding => "UTF-8", :col_sep => ",", :headers => true, :quote_char => "'") do |row|
      r = OpenStruct.new(:name => row[0].blank? ? nil : row[0].to_s,
                         :nature => row[1].downcase.to_sym,
                         :variant => row[2].blank? ? nil : row[2],
                         :born_at => row[3].blank? ? nil : row[3],
                         :brand => row[4].blank? ? nil : row[4].to_s,
                         :model => row[5].blank? ? nil : row[5].to_s,
                         :indicators => row[6].blank? ? nil : row[6].to_s,
                         :notes => row[7].blank? ? nil : row[7].to_s
                         )
    
    product_nature = ProductNature.find_by(:nomen => r.nature) || ProductNature.import_from_nomenclature(r.nature)
                         
    w.check_point
    end


  end

end
