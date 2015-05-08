class Ekylibre::MattersExchanger < ActiveExchanger::Base

  def import
    if building_division = BuildingDivision.first

      rows = CSV.read(file, headers: true).delete_if{|r| r[0].blank?}
      w.count = rows.size

      rows.each do |row|
        next if row[0].blank?
        r = {
          :name => row[0].blank? ? nil : row[0].to_s.strip,
          :variant_reference_name => row[1].blank? ? nil : row[1].downcase.to_sym,
          :work_number => row[2].blank? ? nil : row[2].to_s.strip,
          :place_code => row[3].blank? ? nil : row[3].to_s.strip,
          :born_at => (row[4].blank? ? (Date.today - 200) : row[4]).to_datetime,
          :variety => row[5].blank? ? nil : row[5].to_s.strip,
          :derivative_of => row[6].blank? ? nil : row[6].to_s.strip,
          :external => !row[7].blank?,
          :indicators => row[8].blank? ? {} : row[8].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
            h[i.first.strip.downcase.to_sym] = i.second
            h
          },
          :owner_name => row[7].blank? ? nil : row[7].to_s.strip,
          :notes => row[9].blank? ? nil : row[9].to_s.strip,
          :unit_pretax_amount => row[10].blank? ? nil : row[10].to_d
        }.to_struct

        if r.variant_reference_name
          # find or import from variant reference_nameclature the correct ProductNatureVariant
          variant = ProductNatureVariant.import_from_nomenclature(r.variant_reference_name)
          pmodel = variant.nature.matching_model

          # create a price
          if r.unit_pretax_amount and catalog = Catalog.where(usage: :cost).first and variant.catalog_items.where(catalog_id: catalog.id).empty?
            variant.catalog_items.create!(catalog: catalog, all_taxes_included: false, amount: r.unit_pretax_amount, currency: "EUR")
          end

          # create the owner if not exist
          if r.external == true
            owner = Entity.where(last_name: r.owner_name.to_s).first
            owner ||= Entity.create!(born_at: Date.today, last_name: r.owner_name.to_s, currency: "EUR", language: "fra", nature: "company")
          else
            owner = Entity.of_company
          end

          container = nil
          unless container = Product.find_by_work_number(r.place_code)
            container = building_division
          end

          # create the product
          product = pmodel.create!(variant: variant, work_number: r.work_number,
                                   name: r.name, initial_born_at: r.born_at, initial_owner: owner, variety: r.variety, derivative_of: r.derivative_of, initial_container: container, default_storage: container)

          if r.work_number
            product.work_number = r.work_number
            product.save!
          end

          # create indicators linked to matters
          for indicator, value in r.indicators
            product.read!(indicator, value, at: r.born_at, force: true)
          end

          w.check_point
        else
          w.warn "Need a Variant for #{r.name}"
        end
      end

    else
      w.warn "Need a BuildingDivision"
    end
  end

end
