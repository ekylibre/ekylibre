# frozen_string_literal: true

module Ekylibre
  # CSV File with given columns:
  # A 0: Full name
  # B 1: First name (mandatory)
  # C 2: Last name (mandatory)
  # D 3: Lexicon variant reference name (mandatory) # LEXICON
  # E 4: Work number (mandatory)
  # F 5: Place code (optional)
  # G 6: Born at (recommended)
  # H 7: Notes (not used)
  # I 8: Raw Hourly cost (in EUR)
  # J 9: price indicator (only if no worker contract)
  # K 10: E-mail, used to create user (recommended)
  # L 11: Lexicon worker contract reference name (recommended)
  # M 12: worker contract started_on (recommended)
  class WorkersExchanger < ActiveExchanger::Base
    category :human_resources
    vendor :ekylibre

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
          first_name: row[1].blank? ? nil : row[1].to_s,
          last_name: row[2].blank? ? nil : row[2].to_s,
          variant_reference_name: row[3].blank? ? nil : row[3].to_s.downcase,
          work_number: row[4].blank? ? nil : row[4].to_s,
          place_code: row[5].blank? ? nil : row[5].to_s,
          born_at: (row[6].blank? ? Date.civil(1980, 2, 2) : Date.parse(row[6]).to_datetime),
          notes: row[7].blank? ? nil : row[7].to_s,
          unit_pretax_amount: row[8].blank? ? nil : row[8].to_d,
          price_indicator: row[9].blank? ? nil : row[9].to_sym,
          email: row[10].blank? ? nil : row[10].to_s.downcase.strip,
          worker_contract_reference_name: row[11].blank? ? nil : row[11].to_s,
          worker_contract_started_on: row[12].blank? ? Time.now : Date.parse(row[12]).to_datetime
        }.to_struct

        if r.work_number && Worker.find_by(work_number: r.work_number)
          valid = true
        elsif r.variant_reference_name && MasterVariant.find_by(reference_name: r.variant_reference_name)
          valid = true
        elsif r.variant_reference_name && MasterVariant.find_by(reference_name: r.variant_reference_name).nil?
          w.error "No worker variant exist in LEXICON for #{r.variant_reference_name.inspect}"
          valid = false
        end

        if r.worker_contract_reference_name && MasterDoerContract.find_by(reference_name: r.worker_contract_reference_name).nil?
          w.error "No worker contract exist in LEXICON for #{r.worker_contract_reference_name.inspect}"
          valid = false
        end

        if r.place_code && BuildingDivision.find_by(work_number: r.place_code).nil?
          w.error "No building division exist  for #{r.place_code.inspect}"
          valid = false
        elsif r.place_code && BuildingDivision.find_by(work_number: r.place_code)
          valid = true
        elsif r.place_code.nil? && BuildingDivision.first.nil?
          w.error "You need to create one building division first"
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
          first_name: row[1].blank? ? nil : row[1].to_s,
          last_name: row[2].blank? ? nil : row[2].to_s,
          variant_reference_name: row[3].blank? ? nil : row[3].to_s.downcase,
          work_number: row[4].blank? ? nil : row[4].to_s,
          place_code: row[5].blank? ? nil : row[5].to_s,
          born_at: (row[6].blank? ? Date.civil(1980, 2, 2) : Date.parse(row[6]).to_datetime),
          notes: row[7].blank? ? nil : row[7].to_s,
          unit_pretax_amount: row[8].blank? ? nil : row[8].to_d,
          price_indicator: row[9].blank? ? nil : row[9].to_sym,
          email: row[10].blank? ? nil : row[10].to_s.downcase.strip,
          worker_contract_reference_name: row[11].blank? ? nil : row[11].to_s,
          worker_contract_started_on: row[12].blank? ? Time.now : Date.parse(row[12]).to_datetime
        }.to_struct

        unless (variant = ProductNatureVariant.find_by(work_number: r.variant_reference_name))
          if MasterVariant.find_by(reference_name: r.variant_reference_name)
            variant = ProductNatureVariant.import_from_lexicon(r.variant_reference_name)
          else
            raise "No variant exist in LEXICON for #{r.variant_reference_name.inspect}"
          end
        end
        pmodel = variant.matching_model

        # create a price
        catalog = Catalog.find_by(usage: :cost)
        if r.unit_pretax_amount && catalog && (r.price_indicator == :usage_duration)
          unit = Unit.import_from_lexicon('hour')
          price = variant.catalog_items.find_by(catalog: catalog,
                                                all_taxes_included: false, currency: 'EUR',
                                                unit: unit, started_at: r.worker_contract_started_on)
          unless price
            variant.catalog_items.create!(catalog: catalog,
                                          all_taxes_included: false,
                                          amount: r.unit_pretax_amount,
                                          currency: 'EUR',
                                          unit: unit,
                                          started_at: r.worker_contract_started_on)
          end
        end

        # create the owner if not exist
        unless person = Entity.contacts.find_by(first_name: r.first_name, last_name: r.last_name)
          person = Entity.create!(first_name: r.first_name, last_name: r.last_name, born_at: r.born_at, nature: :contact)
        end
        # set email if present
        person.emails.find_or_create_by!(coordinate: r.email) if r.email.present?

        # create the worker contract if present
        if r.worker_contract_reference_name
          WorkerContract.import_from_lexicon(reference_name: r.worker_contract_reference_name, entity_id: person.id, started_at: r.worker_contract_started_on)
        end

        # create the user
        if person && r.email.present? && User.where(person_id: person.id).none?
          unless user = User.find_by(email: r.email)
            role = Role.order(:id).first
            role ||= Role.import_from_nomenclature(:farm_worker)
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
