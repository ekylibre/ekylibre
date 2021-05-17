# frozen_string_literal: true

module UPRA
  class ReproductorsExchanger < ActiveExchanger::Base
    category :animal_farming
    vendor :upra

    # Create or updates UPRA reproductors
    def import
      male_adult_cow = ProductNatureVariant.import_from_nomenclature(:male_adult_cow)
      # female_adult_cow = ProductNatureVariant.import_from_nomenclature(:female_adult_cow)
      owner_name = 'UPRA Normande'
      owner = Entity.find_by(last_name: owner_name) ||
               Entity.where('last_name ILIKE ?', owner_name).first ||
               Entity.create!(nature: :organization, last_name: owner_name, supplier: true)

      at = Time.zone.now - 36.months

      rows = CSV.read(file, encoding: 'CP1252', col_sep: "\t", headers: true).delete_if { |r| r[4].blank? }
      w.count = rows.size

      rows.each do |row|
        r = OpenStruct.new(
          order: row[0],
          name: row[1],
          identification_number: row[2],
          #:work_number => row[2][-4..-1],
          #:father => row[3],
          #:provider => row[4],
          isu: row[5].to_i,
          inel: row[9].to_i,
          tp: row[10].to_f,
          tb: row[11].to_f
        )
        animal = Animal.create!(
          variant: male_adult_cow,
          name: r.name,
          variety: 'bos_taurus',
          born_at: at,
          identification_number: r.identification_number[-10..-1],
          initial_owner: owner
        )
        # set default indicators
        animal.read!(:unique_synthesis_index,         r.isu.in_unity,  at: at)
        animal.read!(:economical_milk_index,          r.inel.in_unity, at: at)
        animal.read!(:protein_concentration_index,    r.tp.in_unity,   at: at)
        animal.read!(:fat_matter_concentration_index, r.tb.in_unity,   at: at)
        # put in an external localization
        animal.localizations.create!(nature: :exterior)
        w.check_point
      end
    end
  end
end
