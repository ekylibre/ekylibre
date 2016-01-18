class Ekylibre::ActivitiesExchanger < ActiveExchanger::Base
  def check
    valid = true
    rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
    w.count = rows.size
    rows.each do |row|
      r = {
        name: row[0].to_s,
        family: (row[1].blank? ? nil : row[1].to_s),
        variety: (row[2].blank? ? nil : row[2].to_sym)
      }.to_struct

      unless family = Nomen::ActivityFamily[r.family]
        valid = false
      end

      unless variety = Nomen::Variety[r.variety]
        valid = false
      end
    end
    valid
  end

  # Create or updates activities
  def import
    rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
    w.count = rows.size

    rows.each do |row|
      r = {
        name: row[0].to_s,
        family: (row[1].blank? ? nil : row[1].to_s),
        variety: (row[2].blank? ? nil : row[2].to_s)
      }.to_struct

      family = Nomen::ActivityFamily[r.family]

      attributes = if family <= :vegetal_crops
                     {
                       name: r.name,
                       family: :vegetal_crops,
                       cultivation_variety: r.variety,
                       support_variety: :cultivable_zone,
                       with_cultivation: true,
                       with_supports: true,
                       size_indicator: 'net_surface_area',
                       size_unit: 'hectare',
                       nature: :main
                     }
                   elsif family <= :animal_farming
                     {
                       name: r.name,
                       family: :animal_farming,
                       cultivation_variety: r.variety,
                       support_variety: :animal_group,
                       with_cultivation: true,
                       with_supports: true,
                       size_indicator: 'members_population',
                       nature: :main
                     }
                   else
                     {
                       name: r.name,
                       family: r.family,
                       cultivation_variety: r.variety,
                       with_cultivation: true,
                       nature: :main
                     }
                   end
      unless activity = Activity.find_by(attributes.slice(:name, :family, :cultivation_variety))
        activity = Activity.create!(attributes)
      end
      w.check_point
    end
  end
end
