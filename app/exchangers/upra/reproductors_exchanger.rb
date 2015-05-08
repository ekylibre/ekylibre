class UPRA::ReproductorsExchanger < ActiveExchanger::Base

  # Create or updates UPRA reproductors
  def import
    male_adult_cow   = ProductNatureVariant.import_from_nomenclature(:male_adult_cow)
    # female_adult_cow = ProductNatureVariant.import_from_nomenclature(:female_adult_cow)
    owner = Entity.where(of_company: false).reorder(:id).first
    now = Time.now - 2.months

    rows = CSV.read(file, encoding: "CP1252", col_sep: "\t", headers: true).delete_if{|r| r[4].blank?}
    w.count = rows.size

    rows.each do |row|
      r = OpenStruct.new(:order => row[0],
                         :name => row[1],
                         :identification_number => row[2],
                         #:work_number => row[2][-4..-1],
                         #:father => row[3],
                         #:provider => row[4],
                         :isu => row[5].to_i,
                         :inel => row[9].to_i,
                         :tp => row[10].to_f,
                         :tb => row[11].to_f
                        )
      animal = Animal.create!(:variant => male_adult_cow,
                              :name => r.name,
                              :variety => 'bos_taurus',
                              :born_at => '1900-01-01 01:00',
                              :identification_number => r.identification_number[-10..-1],
                              :initial_owner => owner)
      # set default indicators
      animal.read!(:unique_synthesis_index,         r.isu.in_unity,  at: now)
      animal.read!(:economical_milk_index,          r.inel.in_unity, at: now)
      animal.read!(:protein_concentration_index,    r.tp.in_unity,   at: now)
      animal.read!(:fat_matter_concentration_index, r.tb.in_unity,   at: now)
      # put in an external localization
      animal.localizations.create!(nature: :exterior)
      w.check_point
    end
  end

end
