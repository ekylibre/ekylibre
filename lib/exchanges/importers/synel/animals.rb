require 'ffaker'

# Create or updates animals
Exchanges.add_importer :synel_animals do |file, w|

  is_a_demo_instance = Preference.get!(:demo, false, :boolean).value
  variants = {}
  owner = Entity.of_company
  now = Time.now

  rows = CSV.read(file, encoding: "CP1252", col_sep: ";", headers: true).delete_if{|r| r[4].blank?}
  w.count = rows.size

  rows.each do |row|
    born_on = (row[4].blank? ? nil : Date.parse(row[4]))
    dead_on = (row[10].blank? ? nil : Date.parse(row[10]))
    r = OpenStruct.new(:country => row[0],
                       :identification_number => row[1],
                       :work_number => row[2],
                       :name => (row[3].blank? ? ::Faker::Name.first_name + " (MN)" : row[3].capitalize),
                       :born_on => born_on,
                       born_at: (born_on ? born_on.to_datetime + 10.hours : nil),
                       age: (born_on ? (Date.today - born_on) : 0).to_f,
                       :corabo => row[5],
                       :sex => (row[6] == "F" ? :female : :male),
                       # :arrival_cause => (arrival_causes[row[7]] || row[7]),
                       # :initial_arrival_cause => (initial_arrival_causes[row[7]] || row[7]),
                       :arrived_on => (row[8].blank? ? nil : Date.parse(row[8])),
                       # :departure_cause => (departure_causes[row[9]] ||row[9]),
                       :departed_on => dead_on,
                       dead_at: (dead_on ? dead_on.to_datetime : nil)
                      )
    unless animal = Animal.find_by(identification_number: r.identification_number)
      group = nil
      # unless group = groups.detect do |g|
      #          (g.sex.blank? or g.sex.to_s == r.sex.to_s)
      #        end
      # # unless group = groups.detect do |g|
      # #          (g.sex.blank? or g.sex == r.sex) and
      # #            (g.minimum_age.blank? or r.age >= g.minimum_age) and
      # #            (g.maximum_age.blank? or r.age < g.maximum_age)
      # #        end
      #   raise "Cannot find a valid group for the given (for #{r.inspect})"
      # end

      # variants[group.member_nature] ||= ProductNatureVariant.import_from_nomenclature(group.member_nature)
      # variant = variants[group.member_nature]

      # find a bos variety from corabo field in file
      item = Nomen::Varieties.find_by(french_race_code: r.corabo)
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
        # initial_container: group.record.default_storage,
        default_storage: group ? group.record.default_storage : nil
      )
    end
    # Sex is already known but not if the group has no sex
    animal.read!(:sex, r.sex, at: r.born_at) if animal.sex.blank?
    animal.read!(:healthy, true,  at: r.born_at)

    # load demo data weight and state
    if is_a_demo_instance
      weighted_at = r.born_at
      if weighted_at and weighted_at < Time.now
        variation = 0.02
        while (r.dead_at.nil? or weighted_at < r.dead_at) and weighted_at < Time.now
          age = (weighted_at - r.born_at).to_f
          weight = (age < 990 ? 700 * Math.sin(age / (100 * 2 * Math::PI)) + 50.0 : 750)
          weight += rand(weight * variation * 2) - (weight * variation)
          animal.read!(:net_mass, weight.in_kilogram.round(1), at: weighted_at)
          weighted_at += (70 + rand(40)).days + 30.minutes - rand(60).minutes
        end
      end
      # animal.read!(:healthy, true,  at: (now - 3.days))
      # animal.read!(:healthy, false, at: (now - 2.days))
    end

    if group
      group.record.add(animal, r.arrived_on)
      group.record.remove(animal, r.departed_on) if r.departed_on
    end

    w.check_point
  end

end
