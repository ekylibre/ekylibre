# coding: utf-8

class Viniteca::InterventionsExchanger < ActiveExchanger::Base
  def import
    # Unzip file
    dir = w.tmp_dir
    Zip::File.open(file) do |zile|
      zile.each do |entry|
        entry.extract(dir.join(entry.name))
      end
    end

    # load interventions from isaculture

    procedures_transcode = {}.with_indifferent_access
    path = dir.join('procedures_transcode.csv')
    if path.exist?
      CSV.foreach(path, headers: true) do |row|
        procedures_transcode[row[0]] = row[1].to_sym
      end
    end

    variants_transcode = {}.with_indifferent_access
    path = dir.join('variants_transcode.csv')
    if path.exist?
      CSV.foreach(path, headers: true) do |row|
        variants_transcode[row[0]] = row[1].to_sym
      end
    end

    issue_natures_transcode = {}.with_indifferent_access
    path = dir.join('issue_natures_transcode.csv')
    if path.exist?
      CSV.foreach(path, headers: true) do |row|
        issue_natures_transcode[row[0]] = row[1].to_sym
      end
    end

    path = dir.join('interventions.csv')
    if path.exist?

      w.count = path.size

      information_import_context = "Import from viniteca on #{Time.now.l}"

      CSV.foreach(path, headers: true, col_sep: ';') do |row|
        r = OpenStruct.new(cultivable_zone_name: row[1].gsub('-h', '').downcase,
                           working_area: row[2].tr(',', '.').to_d,
                           cultivable_zone_area: row[3].tr(',', '.').to_d,
                           intervention_started_at: (row[4].blank? ? nil : DateTime.strptime(row[4].to_s, '%d/%m/%Y %H:%M')),

                           intervention_stopped_at: (row[5].blank? ? nil : DateTime.strptime(row[5].to_s, '%d/%m/%Y %H:%M')),
                           procedure_name: row[6].to_s.downcase, # to transcode
                           product_name: row[7].to_s.downcase, # to create
                           product_input_population: row[8].tr(',', '.').to_d,
                           product_input_population_per_hectare: row[9].tr(',', '.').to_d,
                           product_input_dose_per_hectare: (row[10].blank? ? nil : row[10].tr(',', '.').to_d), # for legal quantity ?
                           issue_description: (row[11].blank? ? nil : row[11].to_s), # to transcode
                           dar: (row[12].blank? ? nil : row[12].to_i), # indicator on product for delay_before_harvest in day
                           product_input_approved_dose_per_hectare: (row[13].blank? ? nil : row[13].tr(',', '.').to_d) # legal quantity in liter per hectare

                          )

        intervention_started_at = r.intervention_started_at + 9.hours
        intervention_year = intervention_started_at.year
        intervention_month = intervention_started_at.month
        intervention_day = intervention_started_at.day
        intervention_stopped_at = r.intervention_stopped_at + 11.hours

        campaign = Campaign.find_by_harvest_year(intervention_started_at.year)
        campaign ||= Campaign.create!(name: intervention_started_at.year, harvest_year: intervention_started_at.year)
        plant = Plant.find_by_identification_number(r.cultivable_zone_name)

        w.info "----------- #{w.count} -----------".blue
        w.info ' procedure : ' + procedures_transcode[r.procedure_name].inspect.green
        w.info ' variant : ' + variants_transcode[r.product_name].inspect.red
        w.info ' plant : ' + plant.inspect.red

        if plant && campaign
          cultivable_zone = plant.container
          if support = ProductionSupport.where(storage: cultivable_zone).of_campaign(campaign).first
            Ekylibre::FirstRun::Booker.production = support.production
            coeff = (r.working_area / 10_000.0) / 6.0

            #
            # create product
            #

            if r.product_name && (procedures_transcode[r.procedure_name] == :mineral_fertilizing || procedures_transcode[r.procedure_name] == :organic_fertilizing)

              variant = ProductNatureVariant.import_from_nomenclature(variants_transcode[r.product_name])

              intrant = variant.generate(r.product_name, r.intervention_started_at, plant.container)

              unless intrant.frozen_indicators_list.include?(:population)
                intrant.read!(:population, r.product_input_population, at: r.intervention_started_at)
              end

            elsif r.product_name && procedures_transcode[r.procedure_name] == :chemical_weed_killing

              variant = ProductNatureVariant.import_from_nomenclature(:herbicide)

              intrant = variant.generate(r.product_name, r.intervention_started_at, plant.container)
              unless intrant.frozen_indicators_list.include?(:population)
                intrant.read!(:population, r.product_input_population, at: r.intervention_started_at)
              end
              intrant.read!(:wait_before_harvest_period, r.dar.in_day, at: r.intervention_started_at) if r.dar
              intrant.read!(:approved_input_dose, r.product_input_approved_dose_per_hectare.in_kilogram_per_hectare, at: r.intervention_started_at) if r.product_input_approved_dose_per_hectare

            elsif r.product_name && procedures_transcode[r.procedure_name] == :spraying_on_cultivation

              variant = ProductNatureVariant.import_from_nomenclature(:fungicide)

              intrant = variant.generate(r.product_name, r.intervention_started_at, plant.container)

              unless intrant.frozen_indicators_list.include?(:population)
                intrant.read!(:population, r.product_input_population, at: r.intervention_started_at)
              end
              intrant.read!(:wait_before_harvest_period, r.dar.in_day, at: r.intervention_started_at) if r.dar
              intrant.read!(:approved_input_dose, r.product_input_approved_dose_per_hectare.in_kilogram_per_hectare, at: r.intervention_started_at) if r.product_input_approved_dose_per_hectare

            else

              variant = ProductNatureVariant.import_from_nomenclature(:fungicide)

              intrant = variant.generate(r.product_name, r.intervention_started_at, plant.container)
              unless intrant.frozen_indicators_list.include?(:population)
                intrant.read!(:population, r.product_input_population, at: intervention_started_at)
              end
              intrant.read!(:wait_before_harvest_period, r.dar.in_day, at: intervention_started_at) if r.dar
              intrant.read!(:approved_input_dose, r.product_input_approved_dose_per_hectare.in_kilogram_per_hectare, at: intervention_started_at) if r.product_input_approved_dose_per_hectare

            end

            if procedures_transcode[r.procedure_name] && intrant
              #
              # create intervention
              #
              if procedures_transcode[r.procedure_name] == :mineral_fertilizing
                # Mineral fertilizing
                intervention = Ekylibre::FirstRun::Booker.intervene(:mineral_fertilizing, intervention_year, intervention_month, intervention_day, 0.96 * coeff, support: support) do |i|
                  i.add_cast(reference_name: 'fertilizer', actor: intrant)
                  i.add_cast(reference_name: 'fertilizer_to_spread', population: r.product_input_population)
                  i.add_cast(reference_name: 'spreader',    actor: i.find(Product, can: 'spread(preparation)'))
                  i.add_cast(reference_name: 'driver',      actor: i.find(Worker))
                  i.add_cast(reference_name: 'tractor',     actor: i.find(Product, can: 'tow(spreader)'))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              elsif procedures_transcode[r.procedure_name] == :organic_fertilizing

                # Organic fertilizing
                intervention = Ekylibre::FirstRun::Booker.intervene(:organic_fertilizing, intervention_year, intervention_month, intervention_day, 0.96 * coeff, support: support) do |i|
                  i.add_cast(reference_name: 'manure',      actor: intrant)
                  i.add_cast(reference_name: 'manure_to_spread', population: r.product_input_population)
                  i.add_cast(reference_name: 'spreader',    actor: i.find(Product, can: 'spread(preparation)'))
                  i.add_cast(reference_name: 'driver',      actor: i.find(Worker))
                  i.add_cast(reference_name: 'tractor',     actor: i.find(Product, can: 'tow(spreader)'))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              elsif procedures_transcode[r.procedure_name] == :chemical_weed_killing

                # Chemical weed
                intervention = Ekylibre::FirstRun::Booker.intervene(:chemical_weed_killing, intervention_year, intervention_month, intervention_day, 1.07 * coeff, support: support, parameters: { readings: { 'base-chemical_weed_killing-0-800-2' => 'covered' } }) do |i|
                  i.add_cast(reference_name: 'weedkiller', actor: intrant)
                  i.add_cast(reference_name: 'weedkiller_to_spray', population: r.product_input_population)
                  i.add_cast(reference_name: 'sprayer', actor: i.find(Product, can: 'spray'))
                  i.add_cast(reference_name: 'driver',      actor: i.find(Worker))
                  i.add_cast(reference_name: 'tractor',     actor: i.find(Product, can: 'catch'))
                  i.add_cast(reference_name: 'land_parcel', actor: cultivable_zone)
                end

              elsif procedures_transcode[r.procedure_name] == :spraying_on_cultivation

                # Spraying on cultivation
                intervention = Ekylibre::FirstRun::Booker.intervene(:spraying_on_cultivation, intervention_year, intervention_month, intervention_day, 1.07 * coeff, support: support) do |i|
                  i.add_cast(reference_name: 'plant_medicine', actor: intrant)
                  i.add_cast(reference_name: 'plant_medicine_to_spray', population: r.product_input_population)
                  i.add_cast(reference_name: 'sprayer',  actor: i.find(Product, can: 'spray'))
                  i.add_cast(reference_name: 'driver',   actor: i.find(Worker))
                  i.add_cast(reference_name: 'tractor',  actor: i.find(Product, can: 'catch'))
                  i.add_cast(reference_name: 'cultivation', actor: plant)
                end

              else

                w.info 'Intervention is in a black hole'.red

              end

              if intervention
                intervention.description = information_import_context + ' - ' + row[4].to_s + ' - operation : ' + row[6].to_s + ' - support : ' + row[1].to_s + ' - intrant : ' + row[7].to_s
                intervention.save!
                w.info "Intervention n°#{intervention.id} - #{intervention.name} has been created".green
              end

            end

            # create an issue if mentionned
            if r.issue_description && nature = issue_natures_transcode[r.issue_description.downcase]
              issue = Issue.create!(target_type: plant.class.name, target_id: plant.id, priority: 3, observed_at: intervention_started_at, description: r.issue_description, nature: nature, state: 'closed')
              if intervention && issue
                intervention.issue = issue
                intervention.save!
              end
            end

          end
          w.check_point

        end
      end
    end
  end
end
