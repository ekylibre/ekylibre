module Ekylibre
  # CSV File with given columns:
  # A: Full name
  # B: First name (mandatory)
  # C: Last name (mandatory)
  # D: Variant nomen (mandatory)
  # E: Work number (mandatory)
  # F: Place code (optional)
  # G: Born at (recommended)
  # H: Notes (not used)
  # I: Hourly cost (in EUR)
  # J: E-mail, used to create user
  class WorkersExchanger < ActiveExchanger::Base
    def check
      valid = true

      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size

      rows.each_with_index do |row, index|
        line_number = index + 2
        prompt = "L#{line_number.to_s.yellow}"
        next if row[0].blank?
        r = {
          name: row[0].blank? ? nil : row[0].to_s,
          first_name: row[1],
          last_name: row[2],
          variant_reference_name: row[3].blank? ? nil : row[3].to_s,
          work_number: row[4],
          place_code: row[5],
          born_at: (row[6].blank? ? Date.civil(1980, 2, 2) : Date.parse(row[6]).to_datetime),
          notes: row[7].to_s,
          unit_pretax_amount: row[8].blank? ? nil : row[8].to_d,
          price_indicator: row[9].blank? ? nil : row[9].to_sym,
          email: row[10]
        }.to_struct

        next unless r.variant_reference_name
        next if variant = ProductNatureVariant.find_by(work_number: r.variant_reference_name)
        unless nomen = Nomen::ProductNatureVariant.find(r.variant_reference_name.downcase.to_sym)
          w.error "No variant exist in NOMENCLATURE for #{r.variant_reference_name.inspect}"
          valid = false
        end
      end
    end

    def import
      building_division = BuildingDivision.first

      rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
      w.count = rows.size

      rows.each do |row|
        r = {
          name: row[0].blank? ? nil : row[0].to_s,
          first_name: row[1],
          last_name: row[2],
          variant_reference_name: row[3].blank? ? nil : row[3].to_s,
          work_number: row[4],
          place_code: row[5],
          born_at: (row[6].blank? ? Date.civil(1980, 2, 2) : Date.parse(row[6]).to_datetime),
          notes: row[7].to_s,
          unit_pretax_amount: row[8].blank? ? nil : row[8].to_d,
          price_indicator: row[9].blank? ? nil : row[9].to_sym,
          email: row[10]
        }.to_struct

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
        unless person = Entity.contacts.find_by(first_name: r.first_name, last_name: r.last_name)
          person = Entity.create!(first_name: r.first_name, last_name: r.last_name, born_at: r.born_at, nature: :contact)
        end

        person.emails.find_or_create_by!(coordinate: r.email) if r.email.present?

        # create the user
        if person && r.email.present? && !User.where(person_id: person.id).any?
          unless user = User.find_by(email: r.email)
            role = Role.order(:id).first
            role = Role.import_from_nomenclature(:farm_worker) unless role
            password = User.generate_password(100, :hard)
            user = User.create!(
              first_name: r.first_name,
              last_name: r.last_name,
              person: person,
              email: r.email,
              password: password,
              password_confirmation: password,
              language: Preference[:language],
              role: role
            )
          end
          unless user.person
            user.person = person
            user.save!
          end
        end

        owner = Entity.of_company

        container = Product.find_by(work_number: r.place_code) || building_division

        # create the worker
        worker = pmodel.create!(variant: variant, name: r.name, initial_born_at: r.born_at, initial_owner: owner, default_storage: container, work_number: r.work_number, person: person)

        # attach georeading if exist for worker
        if georeading = Georeading.find_by(number: r.work_number, nature: :point)
          worker.read!(:geolocation, georeading.content, at: r.born_at, force: true)
        end

        w.check_point
      end
    end
  end
end
