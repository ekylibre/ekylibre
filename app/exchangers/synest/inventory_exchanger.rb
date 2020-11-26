module Synest
  class InventoryExchanger < ActiveExchanger::Base
    category :stocks
    vendor :synest

    # Create or updates Synel Inventories
    def import
      male_adult_cow = ProductNatureVariant.import_from_nomenclature(:male_adult_cow)
      place = BuildingDivision.last # find_by_work_number("B07_D2")
      owner = Entity.where(of_company: false).reorder(:id).first

      rows = CSV.read(file, encoding: 'CP1252', col_sep: ';', headers: true)
      w.count = rows.size

      # FILE DESCRIPTION
      # COPAIP - 0 - Country
      # NUNATI - 1 - identification number
      # NUTRAV - 2 - work number
      # NOBOVI - 3 - Name
      # DANAIS - 4 - born_on
      # TYRASU - 5 - variety french_race_code
      # SEXBOV - 6 - sex
      # CAUSEN - 7 - incoming_cause
      # DATEEN - 8 - incoming_on
      # CAUSSO - 9 - outgoing_cause
      # DATESO - 10 - outgoing_on
      # COPAME - 15 - mother country
      # NUMERE - 16 - mother_identification_number
      # NOMERE - 17 - mother_name
      # TRAMER - 18 - mother french_race_code
      # COPAME - 19 - father country
      # NUMERE - 20 - father_identification_number
      # NOMERE - 21 - father_name
      # TRAMER - 22 - father french_race_code

      # find animals credentials in preferences
      identifier = Identifier.find_by(nature: :cattling_root_number)
      cattling_root_number = identifier ? identifier.value : '??????????'
      parents = { mother: {}, father: {} }

      rows.each do |row|
        born_on = (row[4].blank? ? nil : Date.parse(row[4]))
        incoming_on = (row[8].blank? ? nil : Date.parse(row[8]))
        outgoing_on = (row[10].blank? ? nil : Date.parse(row[10]))

        r = OpenStruct.new(
          work_number: row[2],
          identification_number: (row[1] ? row[1].to_s : nil),
          name: (row[3].blank? ? FFaker::Name.first_name + ' (MN)' : row[3].capitalize),
          mother_variety_code: (row[18].blank? ? nil : row[18]),
          father_variety_code: (row[22].blank? ? nil : row[22]),
          sex: (row[6].blank? ? nil : (row[6] == 'F' ? :female : :male)),
          born_on: born_on,
          born_at: (born_on ? born_on.to_datetime + 10.hours : nil),
          incoming_cause: row[7],
          incoming_on: incoming_on,
          incoming_at: (incoming_on ? incoming_on.to_datetime + 10.hours : nil),
          mother_identification_number: row[16],
          mother_work_number: (row[16] ? row[16][-4..-1] : nil),
          mother_name: (row[17].blank? ? FFaker::Name.first_name : row[17].capitalize),
          father_identification_number: row[20],
          father_work_number: (row[20] ? row[20][-4..-1] : nil),
          father_name: (row[21].blank? ? FFaker::Name.first_name : row[21].capitalize),
          outgoing_cause: row[9],
          outgoing_on: outgoing_on,
          outgoing_at: (outgoing_on ? outgoing_on.to_datetime + 10.hours : nil)
        )
        # check if animal is present in DB
        if animal = Animal.find_by(identification_number: r.identification_number)
          animal.initial_dead_at = r.outgoing_at
          animal.save!
        else
          group = nil

          # find a bos variety from corabo field in file
          item = Onoma::Variety.find_by(french_race_code: r.corabo)
          variety = (item ? item.name : :bos_taurus)
          variant = ProductNatureVariant.import_from_nomenclature(r.sex == :male ? :male_adult_cow : :female_adult_cow)

          animal = Animal.create!(
            variant: variant,
            name: r.name,
            variety: variety,
            identification_number: r.identification_number,
            work_number: r.work_number,
            initial_born_at: r.born_at,
            initial_dead_at: r.outgoing_at,
            initial_owner: owner,
            initial_population: 1.0,
            # initial_container: group.record.default_storage,
            default_storage: group ? group.record.default_storage : nil
          )
        end

        if group
          animal.memberships.create!(group: group.record, started_at: arrived_on, nature: :interior)
          animal.memberships.create!(started_at: departed_on, nature: :exterior) if r.departed_on
        end

        # Find mother
        unless r.mother_identification_number.blank? &&
               Animal.find_by(identification_number: r.mother_identification_number)
          parents[:mother][r.mother_identification_number] ||=
            Animal.find_by(identification_number: r.mother_identification_number)
          link = animal.links.new(nature: :mother, started_at: animal.born_at)
          link.linked = parents[:mother][r.mother_identification_number]
          link.save
        end

        # find a the father variety from field in file
        father_items = Onoma::Variety.where(french_race_code: r.father_variety_code)
        father_bos_variety = father_items ? father_items.first.name : 'bos'

        # Find or create father
        if r.father_identification_number.present?
          father = parents[:father][r.father_identification_number] ||=
                     Animal.find_by(identification_number: r.father_identification_number) ||
                     Animal.create!(
                       variant_id: male_adult_cow.id,
                       name: r.father_name,
                       variety: father_bos_variety,
                       identification_number: r.father_identification_number,
                       work_number: r.father_work_number,
                       initial_owner: owner,
                       initial_population: 1.0
                     )
          father.localizations.create!(nature: :exterior)
          link = animal.links.new(nature: :father, started_at: animal.born_at)
          link.linked = parents[:father][r.father_identification_number]
          link.save
        end
        w.check_point
      end
      parents = nil
    end
  end
end
