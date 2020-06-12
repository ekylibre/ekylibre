module Ekylibre
  class MattersExchanger < ActiveExchanger::Base
    def check
      valid = true

      # Check building division presence
      unless building_division = BuildingDivision.first
        w.error 'Need almost one BuildingDivision'
        valid = false
      end

      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size
      rows.each_with_index do |row, index|
        line_number = index + 2
        prompt = "L#{line_number.to_s.yellow}"
        next if row[0].blank?
        r = {
          name: row[0].blank? ? nil : row[0].to_s.strip,
          variant_reference_name: row[1].blank? ? nil : row[1].to_s,
          work_number: row[2].blank? ? nil : row[2].to_s.strip,
          place_code: row[3].blank? ? nil : row[3].to_s.strip,
          born_at: (row[4].blank? ? (Time.zone.today - 200) : row[4]).to_datetime,
          variety: row[5].blank? ? nil : row[5].to_s.strip,
          derivative_of: row[6].blank? ? nil : row[6].to_s.strip,
          external: row[7].present?,
          indicators: row[8].blank? ? {} : row[8].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each_with_object({}) do |i, h|
            h[i.first.strip.downcase.to_sym] = i.second
            h
          end,
          owner_name: row[7].blank? ? nil : row[7].to_s.strip,
          notes: row[9].blank? ? nil : row[9].to_s.strip,
          unit_pretax_amount: row[10].blank? ? nil : row[10].to_d
        }.to_struct

        # FILE GIVE VARIANT OR VARIETY CODES BUT NOT EXIST IN DB OR IN NOMENCLATURE
        if r.variety
          unless Nomen::Variety.find(r.variety)
            w.error "#{prompt} #{r.variety} does not exist in NOMENCLATURE"
            valid = false
          end
        end

        next unless r.variant_reference_name
        next if variant = ProductNatureVariant.find_by(work_number: r.variant_reference_name.downcase.to_sym)
        if Variant.find_by(reference_name: r.variant_reference_name.downcase.to_sym)
          valid = true
        elsif nomen = Nomen::ProductNatureVariant.find(r.variant_reference_name.downcase.to_sym)
          valid = true
        else
          w.error "No variant exist in NOMENCLATURE for #{r.variant_reference_name.inspect}"
          valid = false
        end
      end
      valid
    end

    def import
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size

      currency = Preference[:currency]
      building_division = BuildingDivision.first

      rows.each do |row|
        next if row[0].blank?
        r = {
          name: row[0].blank? ? nil : row[0].to_s.strip,
          variant_reference_name: row[1].blank? ? nil : row[1].to_s,
          work_number: row[2].blank? ? nil : row[2].to_s.strip,
          place_code: row[3].blank? ? nil : row[3].to_s.strip,
          born_at: (row[4].blank? ? (Time.zone.today - 200) : row[4]).to_datetime,
          variety: row[5].blank? ? nil : row[5].to_s.strip,
          derivative_of: row[6].blank? ? nil : row[6].to_s.strip,
          external: row[7].present?,
          indicators: row[8].blank? ? {} : row[8].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each_with_object({}) do |i, h|
            h[i.first.strip.downcase.to_sym] = i.second
            h
          end,
          owner_name: row[7].blank? ? nil : row[7].to_s.strip,
          notes: row[9].blank? ? nil : row[9].to_s.strip,
          unit_pretax_amount: row[10].blank? ? nil : row[10].to_d
        }.to_struct

        if r.variant_reference_name
          # find or import from variant reference_nameclature the correct ProductNatureVariant
          variant = ProductNatureVariant.find_by(work_number: r.variant_reference_name)
          variant ||= ProductNatureVariant.find_by(reference_name: r.variant_reference_name)
          unless variant
            # if phyto product found with maaid
            if RegisteredPhytosanitaryProduct.find_by_id(r.variant_reference_name)
              item = RegisteredPhytosanitaryProduct.find_by_id(r.variant_reference_name)
              variant = ProductNatureVariant.import_phyto_from_lexicon(item.reference_name)
            elsif Nomen::ProductNatureVariant.find(r.variant_reference_name.downcase.to_sym)
              variant = ProductNatureVariant.import_from_nomenclature(r.variant_reference_name.downcase.to_sym)
            else
              raise "No variant exist in NOMENCLATURE for #{r.variant_reference_name.inspect}"
            end
          end

          # create a price
          catalog = Catalog.find_by(usage: :cost)
          if variant && r.unit_pretax_amount && catalog && catalog.items.where(variant: variant).empty?
            attributes = {catalog: catalog, all_taxes_included: false, amount: r.unit_pretax_amount, currency: currency}
            variant.catalog_items.create!(attributes)
          end

          # create the owner if not exist
          if r.external == true
            owner = Entity.find_by(last_name: r.owner_name.to_s)
            owner ||= Entity.create!(
              born_at: Time.zone.today,
              last_name: r.owner_name.to_s,
              currency: Preference[:currency],
              language: Preference[:language],
              nature: :organization
            )
          else
            owner = Entity.of_company
          end

          container = nil
          unless (container = Product.find_by(work_number: r.place_code))
            container = building_division
          end

          # create the product
          if variant
            pmodel = variant.matching_model
            matter = pmodel.create!(
              variant: variant,
              work_number: r.work_number,
              name: r.name,
              initial_born_at: r.born_at,
              initial_population: r.indicators[:population].to_f,
              initial_owner: owner,
              variety: r.variety,
              derivative_of: r.derivative_of,
              initial_container: container,
              default_storage: container
            )
          else
            raise "No variant created or no matching model for #{r.variant_reference_name.inspect}"
          end

          if matter && r.work_number
            matter.work_number = r.work_number
            matter.save!
            # create indicators linked to matters
            r.indicators.each do |indicator, value|
              next unless indicator != :population
              matter.read!(indicator, value, at: r.born_at, force: true)
            end
          end

          w.check_point
        else
          w.warn "Need a Variant for #{r.name}"
        end
      end
    end
  end
end
