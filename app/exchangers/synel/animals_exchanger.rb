module Synel
  class AnimalsExchanger < ActiveExchanger::Base
    # Create or updates animals
    def import
      demo_mode = Preference.value(:demo, false, :boolean)
      variants = {}
      owner = Entity.of_company
      now = Time.zone.now

      rows = CSV.read(file, encoding: 'CP1252', col_sep: ';', headers: true).delete_if { |r| r[4].blank? }
      w.count = rows.size

      rows.each do |row|
        born_on = (row[4].blank? ? nil : Date.parse(row[4]))
        dead_on = (row[10].blank? ? nil : Date.parse(row[10]))
        r = OpenStruct.new(
          country: row[0],
          identification_number: row[1],
          work_number: row[2],
          name: (row[3].blank? ? FFaker::Name.first_name + ' (MN)' : row[3].capitalize),
          born_on: born_on,
          born_at: (born_on ? born_on.to_datetime + 10.hours : nil),
          age: (born_on ? (Time.zone.today - born_on) : 0).to_f,
          corabo: row[5],
          sex: (row[6] == 'F' ? :female : :male),
          # :arrival_cause => (arrival_causes[row[7]] || row[7]),
          # :initial_arrival_cause => (initial_arrival_causes[row[7]] || row[7]),
          arrived_on: (row[8].blank? ? nil : Date.parse(row[8])),
          # :departure_cause => (departure_causes[row[9]] ||row[9]),
          departed_on: dead_on,
          dead_at: (dead_on ? dead_on.to_datetime + 20.hours : nil)
        )
        unless animal = Animal.find_by(identification_number: r.identification_number)
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
            initial_dead_at: r.dead_at,
            initial_owner: owner,
            initial_population: 1.0,
            # initial_container: group.record.default_storage,
            default_storage: group ? group.record.default_storage : nil
          )
        end
        # Sex is already known but not if the group has no sex
        # animal.read!(:sex, r.sex, at: r.born_at) if animal.sex.blank?
        animal.read!(:healthy, true, at: r.born_at)

        if group
          animal.memberships.create!(group: group.record, started_at: arrived_on, nature: :interior)
          animal.memberships.create!(started_at: departed_on, nature: :exterior) if r.departed_on
        end

        w.check_point
      end
    end
  end
end
