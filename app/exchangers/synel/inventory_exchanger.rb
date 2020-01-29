module Synel
  class InventoryExchanger < ActiveExchanger::Base
    # Create or updates Synel Inventories
    def import
      male_adult_cow = ProductNatureVariant.import_from_nomenclature(:male_adult_cow)
      place = BuildingDivision.last # find_by_work_number("B07_D2")
      owner = Entity.where(of_company: false).reorder(:id).first

      rows = CSV.read(file, encoding: 'CP1252', col_sep: "\t", headers: true)
      w.count = rows.size

      # find animals credentials in preferences
      identifier = Identifier.find_by(nature: :cattling_root_number)
      cattling_root_number = identifier ? identifier.value : '??????????'
      parents = { mother: {}, father: {} }

      rows.each do |row|
        born_on = (row[4].blank? ? nil : Date.parse(row[4]))
        incoming_on = (row[6].blank? ? nil : Date.parse(row[6]))
        outgoing_on = (row[12].blank? ? nil : Date.parse(row[12]))

        r = OpenStruct.new(
          work_number: row[0],
          identification_number: (row[0] ? cattling_root_number + row[0].to_s : nil),
          name: (row[1].blank? ? FFaker::Name.first_name + ' (MN)' : row[1].capitalize),
          mother_variety_code: (row[13].blank? ? nil : row[13]),
          father_variety_code: (row[14].blank? ? nil : row[14]),
          sex: (row[3].blank? ? nil : (row[3] == 'F' ? :female : :male)),
          born_on: born_on,
          born_at: (born_on ? born_on.to_datetime + 10.hours : nil),
          incoming_cause: row[5],
          incoming_on: incoming_on,
          incoming_at: (incoming_on ? incoming_on.to_datetime + 10.hours : nil),
          mother_identification_number: row[7],
          mother_work_number: (row[7] ? row[7][-4..-1] : nil),
          mother_name: (row[8].blank? ? FFaker::Name.first_name : row[8].capitalize),
          father_identification_number: row[9],
          father_work_number: (row[9] ? row[9][-4..-1] : nil),
          father_name: (row[10].blank? ? FFaker::Name.first_name : row[10].capitalize),
          outgoing_cause: row[11],
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
          item = Nomen::Variety.find_by(french_race_code: r.corabo)
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
            default_storage: group ? group.record.default_storage : nil
          )
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
        father_items = Nomen::Variety.where(french_race_code: r.father_variety_code)
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

      true
    end
  end
end
