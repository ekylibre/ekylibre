module Ekylibre
  class EquipmentsExchanger < ActiveExchanger::Base
    # Create or updates equipments
    def import
      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size

      rows.each do |row|
        r = {
          name: row[0].blank? ? nil : row[0].to_s,
          variant_reference_name: row[1].blank? ? nil : row[1].to_sym,
          work_number: row[2].blank? ? nil : row[2].to_s,
          place_code: row[3].blank? ? nil : row[3].to_s,
          born_at: (row[4].blank? ? Date.civil(2000, 2, 2) : row[4]).to_datetime,
          brand: row[5].blank? ? nil : row[5].to_s,
          model: row[6].blank? ? nil : row[6].to_s,
          external: row[7].present?,
          owner_name: row[7].blank? ? nil : row[7].to_s,
          indicators: row[8].blank? ? {} : row[8].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each_with_object({}) do |i, h|
            h[i.first.strip.downcase.to_sym] = i.second
            h
          end,
          notes: row[9].blank? ? nil : row[9].to_s,
          unit_pretax_amount: row[10].blank? ? nil : row[10].tr(',', '.').to_d,
          price_indicator: row[11].blank? ? nil : row[11].to_sym
        }.to_struct

        unless r.variant_reference_name
          w.warn "Need a Variant for #{r.name}"
          next
        end

        # find or import from variant reference_nameclature the correct ProductNatureVariant
        unless (variant = ProductNatureVariant.find_by(work_number: r.variant_reference_name))
          if Nomen::ProductNatureVariant.find(r.variant_reference_name.downcase.to_sym)
            variant = ProductNatureVariant.import_from_nomenclature(r.variant_reference_name.downcase.to_sym)
          else
            raise "No variant exist in NOMENCLATURE for #{r.variant_reference_name.inspect}"
          end
        end
        pmodel = variant.matching_model

        # create a price
        catalog = Catalog.find_by(usage: :cost)
        if r.unit_pretax_amount && catalog && catalog.items.where(variant: variant).empty?
          variant.catalog_items.create!(catalog: catalog, all_taxes_included: false, amount: r.unit_pretax_amount, currency: 'EUR') # , indicator_name: r.price_indicator.to_s
        end

        # create the owner if not exist
        if r.external == true
          owner = Entity.where(last_name: r.owner_name.to_s).first
          owner ||= Entity.create!(born_at: Time.zone.today, last_name: r.owner_name.to_s, currency: Preference[:currency], language: Preference[:language], nature: :organization)
        else
          owner = Entity.of_company
        end

        container = r.place_code.present? ? Product.find_by(work_number: r.place_code) : nil

        # Extract population from indicators
        population = r.indicators.fetch(:population, 1).to_i

        if population > 1 && variant.population_counting_unitary?
          raise StandardError.new(I18n.t('errors.messages.invalid_population_for_unitary_product', name: r.name, population: population))
        end

        # create the equipment
        equipment = pmodel.create!(
          variant_id: variant.id,
          name: r.name,
          initial_born_at: r.born_at,
          initial_population: population,
          initial_owner: owner,
          initial_container: container,
          default_storage: container,
          work_number: r.work_number
        )

        # create indicators linked to equipment
        r.indicators.except(:population).each do |(indicator, value)|
          equipment.read!(indicator, value, at: r.born_at, force: true)
        end

        # attach georeading if exist for equipment
        if equipment
          if (georeading = Georeading.find_by(number: r.work_number, nature: :polygon))
            equipment.read!(:shape, georeading.content, at: r.born_at, force: true)
          end
          if (georeading = Georeading.find_by(number: r.work_number, nature: :point))
            equipment.read!(:geolocation, georeading.content, at: r.born_at, force: true)
          end
        end

        w.check_point
      end
    end
  end
end
