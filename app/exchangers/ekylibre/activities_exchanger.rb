module Ekylibre
  # Permits to import activities from a CSV file with 3 columns:
  #  - Name
  #  - Family (from nomenclature ActivityFamily)
  #  - Cultivation variety (from nomenclature Variety)
  class ActivitiesExchanger < ActiveExchanger::Base
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
        valid = false unless Nomen::ActivityFamily.find(r.family)
        valid = false unless Nomen::Variety.find(r.variety)
        w.check_point
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

        family = Nomen::ActivityFamily.find(r.family)

        attributes = {
          name: r.name,
          family: r.family,
          cultivation_variety: r.variety,
          with_cultivation: true,
          production_cycle: :annual,
          nature: :main
        }
        if family <= :plant_farming
          attributes.update(
            family: :plant_farming,
            cultivation_variety: r.variety,
            support_variety: :cultivable_zone,
            with_supports: true,
            size_indicator: 'net_surface_area',
            size_unit: 'hectare'
          )
        elsif family <= :animal_farming
          attributes.update(
            family: :animal_farming,
            cultivation_variety: r.variety,
            support_variety: :animal_group,
            with_supports: true,
            size_indicator: 'members_population'
          )
        elsif family <= :administering
          attributes.update(
            family: :administering,
            with_cultivation: false,
            with_supports: false,
            cultivation_variety: nil,
            support_variety: nil,
            nature: :auxiliary
          )
        end
        activity = Activity.find_or_initialize_by(attributes.slice(:name, :family, :cultivation_variety))
        activity.attributes = attributes
        activity.save!
        w.check_point
      end
    end
  end
end
