# -*- coding: utf-8 -*-
demo :interventions do

  class Booker

    cattr_accessor :production

    class << self

      def find(model, options = {})
        relation = model
        relation = relation.can(options[:can]) if options[:can]
        relation = relation.of_variety(options[:variety]) if options[:variety]
        relation = relation.derivative_of(options[:derivative_of]) if options[:derivative_of]
        if record = relation.all.sample
          return record
        else
          # Create product with given elements
          attributes = {
            name: model.model_name.human,
            default_storage: find(BuildingDivision)
          }
          variants = ProductNatureVariant.find_or_import!(options[:variety] || model.name.underscore, derivative_of: options[:derivative_of])
          variants.can(options[:can]) if options[:can]
          unless attributes[:variant] = variants.first
            raise StandardError, "Cannot find product variant with options #{options.inspect}"
          end
          return model.create!(attributes)
        end
      end

      def daytime_duration(on)
        12.0 - 4.0 * Math.cos((on + 11.days).yday.to_f / (365.25 / Math::PI / 2))
      end

      def sunrise(on, shift = 1.5)
        return shift + (24.0 - self.daytime_duration(on)) / 2.0
      end

      def sunset(on, shift = 1.5)
        self.daytime_duration(on) + self.sunrise(on, shift)
      end


      # Duration is expected to be in hours
      def intervene(procedure, year, month, day, duration, options = {}, &block)
        day_range = options[:range] || 30

        duration += 1.25 - rand(0.5)

        # Find actors
        booker = new(Time.new(year, month, day), duration)
        yield booker
        actors = booker.casts.collect{|c| c[:actor]}.compact
        if actors.empty?
          raise ArgumentError, "What's the fuck ? No actors ? "
        end

        # Adds fixed durations to given time
        procedure_name = "#{options[:namespace]}:#{procedure}-#{options[:version] || '0.0'}"
        unless Procedo[procedure_name]
          raise ArgumentError, "Unknown procedure #{procedure} (#{procedure_name})"
        end
        duration += Procedo[procedure_name].fixed_duration / 3600

        # Estimate number of days to work
        duration_days = (duration / 8.0).ceil

        # Find a slot for all actors for given number of day
        on = nil
        begin
          on = Date.civil(year, month, day) + rand(day_range - duration_days).days
        end while InterventionCast.joins(:intervention).where(actor_id: actors.map(&:id)).where("? BETWEEN started_at AND stopped_at OR ? BETWEEN started_at AND stopped_at", on, on + duration_days).any?

        # Compute real number of day
        # 11 days shifting is here respect solstice shifting with 1st day of year
        daytime_duration = self.daytime_duration(on) - 2.0
        if duration > daytime_duration
          duration_days = (duration.to_f / daytime_duration).ceil
        end

        # Split into many interventions
        periods = []
        total = duration * 1.0
        duration_days.times do
          started_at = on.to_time + self.sunrise(on).hours + 1.hour
          d = self.daytime_duration(on) - 2.0
          d = total if d > total
          periods << {started_at: started_at, duration: d * 3600} if d > 0
          total -= d
          on += 1
        end

        # Run interventions
        intervention = nil
        for period in periods
          # int = Intervention.run!({reference_name: procedure_name, production: Booker.production, production_support: options[:support], started_at: period[:started_at], stopped_at: (period[:started_at] + period[:duration])}, period, &block)
          intervention = Intervention.create!(reference_name: procedure_name, production: Booker.production, production_support: options[:support], started_at: period[:started_at], stopped_at: (period[:started_at] + period[:duration]))
          for cast in booker.casts
            intervention.add_cast!(cast)
          end
          intervention.run!(period)
        end
        return intervention
      end

    end

    attr_reader :casts, :duration, :started_at

    def initialize(started_at, duration)
      @duration = duration
      @started_at = started_at
      @casts = []
    end

    def add_cast(options = {})
      @casts << options
    end

    # Find a valid actor in the given period
    def find(model, options = {})
      options.update(started_at: @started_at)
      options.update(stopped_at: @started_at)
      self.class.find(model, options)
    end

  end

  # RubyProf.start

  # interventions for all poaceae
  Ekylibre::fixturize :cultural_interventions do |w|
    for production in Production.all
      variety = production.variant.variety
      if Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:poaceae])
        year = production.campaign.name.to_i
        Booker.production = production
        for support in production.supports
          land_parcel = support.storage
          if area = land_parcel.shape_area
            coeff = (area.to_s.to_f / 10000.0) / 6.0
            # 7.99 -> 20.11 -> 40.21

            # Plowing 15-09-N -> 15-10-N
            Booker.intervene(:plowing, year - 1, 9, 15, 9.78 * coeff, support: support) do |i|
              i.add_cast(reference_name: 'driver',  actor: i.find(Worker))
              i.add_cast(reference_name: 'tractor', actor: i.find(Product, can: "tow(plower)"))
              i.add_cast(reference_name: 'plow',    actor: i.find(Product, can: "plow"))
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
            end

            # Sowing 15-10-N -> 30-10-N
            int = Booker.intervene(:sowing, year - 1, 10, 15, 6.92 * coeff, range: 15, support: support) do |i|
              i.add_cast(reference_name: 'seeds',        actor: i.find(Product, variety: :seed, derivative_of: variety))
              i.add_cast(reference_name: 'seeds_to_sow', population: 20)
              i.add_cast(reference_name: 'sower',        actor: i.find(Product, can: "sow"))
              i.add_cast(reference_name: 'driver',       actor: i.find(Worker))
              i.add_cast(reference_name: 'tractor',      actor: i.find(Product, can: "tow(sower)"))
              i.add_cast(reference_name: 'land_parcel',  actor: land_parcel)
              i.add_cast(reference_name: 'culture',      variant: ProductNatureVariant.find_or_import!(variety).first, population: (area.to_s.to_f / 10000.0))
            end

            culture = int.casts.find_by(reference_name: 'culture').actor

            # Fertilizing  01-03-M -> 31-03-M
            Booker.intervene(:mineral_fertilizing, year, 3, 1, 0.96 * coeff, support: support) do |i|
              i.add_cast(reference_name: 'fertilizer',  actor: i.find(Product, variety: :mineral_matter))
              i.add_cast(reference_name: 'fertilizer_to_spread', population: 0.4 + coeff * rand(0.6))
              i.add_cast(reference_name: 'spreader',    actor: i.find(Product, can: "spread(mineral_matter)"))
              i.add_cast(reference_name: 'driver',      actor: i.find(Worker))
              i.add_cast(reference_name: 'tractor',     actor: i.find(Product, can: "tow(spreader)"))
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
            end

            # Organic Fertilizing  01-03-M -> 31-03-M
            Booker.intervene(:organic_fertilizing, year, 3, 1, 0.96 * coeff, support: support) do |i|
              i.add_cast(reference_name: 'manure',      actor: i.find(Product, variety: :manure, derivative_of: :bos))
              i.add_cast(reference_name: 'manure_to_spread', population: 0.2 + 4 * coeff)
              i.add_cast(reference_name: 'spreader',    actor: i.find(Product, can: "spread(organic_matter)"))
              i.add_cast(reference_name: 'driver',      actor: i.find(Worker))
              i.add_cast(reference_name: 'tractor',     actor: i.find(Product, can: "tow(spreader)"))
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
            end

            if w.count.modulo(3).zero? # AND NOT prairie
              # Treatment herbicide 01-04 30-04
              Booker.intervene(:chemical_treatment, year, 4, 1, 1.07 * coeff, support: support) do |i|
                i.add_cast(reference_name: 'molecule', actor: i.find(Product, can: "kill(plant)"))
                i.add_cast(reference_name: 'molecule_to_spray', population: 0.18 + 0.9 * coeff)
                i.add_cast(reference_name: 'sprayer',  actor: i.find(Product, can: "spray"))
                i.add_cast(reference_name: 'driver',   actor: i.find(Worker))
                i.add_cast(reference_name: 'tractor',  actor: i.find(Product, can: "catch"))
                i.add_cast(reference_name: 'culture',  actor: culture)
              end
            end

          end
          w.check_point
        end
      end
    end
  end

  # interventions for grass
  Ekylibre::fixturize :grass_interventions do |w|
    for production in Production.all
      variety = production.variant.variety
      if Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:poa])
        year = production.campaign.name.to_i
        Booker.production = production
        for support in production.supports
          land_parcel = support.storage
          if area = land_parcel.shape_area
            coeff = (area.to_s.to_f / 10000.0) / 6.0

            bob = nil
            sowing = support.interventions.where(reference_name: "sowing").where("started_at < ?", Date.civil(year, 6, 6)).order("stopped_at DESC").first
            if culture = sowing.casts.find_by(reference_name: 'culture').actor rescue nil
              int = Booker.intervene(:plant_mowing, year, 6, 6, 2.8 * coeff, support: support) do |i|
                bob = i.find(Worker)
                i.add_cast(reference_name: 'mower_driver', actor: bob)
                i.add_cast(reference_name: 'tractor',      actor: i.find(Product, can: "tow(mower)"))
                i.add_cast(reference_name: 'mower',        actor: i.find(Product, can: "mow"))
                i.add_cast(reference_name: 'culture',      actor: culture)
                i.add_cast(reference_name: 'straw', population: 1.5 * coeff, variant: ProductNatureVariant.find_or_import!(:straw, derivative_of: culture.variety).first)
              end

              straw = int.casts.find_by_reference_name('straw').actor
              Booker.intervene(:straw_bunching, year, 6, 20, 3.13 * coeff, support: support) do |i|
                i.add_cast(reference_name: 'tractor',        actor: i.find(Product, can: "tow(baler)"))
                i.add_cast(reference_name: 'baler_driver',   actor: i.find(bob.others))
                i.add_cast(reference_name: 'baler',          actor: i.find(Product, can: "bunch"))
                i.add_cast(reference_name: 'straw_to_bunch', actor: straw)
                i.add_cast(reference_name: 'straw_bales', population: 1.5 * coeff, variant: ProductNatureVariant.import_from_nomenclature(culture.variety.to_s == 'triticum_durum' ? :hard_wheat_straw_bales : :wheat_straw_bales))
              end
            end
          end
          w.check_point
        end
      end
    end
  end

  # interventions for cereals
  Ekylibre::fixturize :cereals_interventions do |w|
    for production in Production.all
      variety = production.variant.variety
      if Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:triticum_aestivum]) || Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:triticum_durum]) || Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:zea]) || Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:hordeum])
        year = production.campaign.name.to_i
        Booker.production = production
        for support in production.supports
          land_parcel = support.storage
          if area = land_parcel.shape_area
            coeff = (area.to_s.to_f / 10000.0) / 6.0
            # Harvest 01-07-M 30-07-M
            sowing = support.interventions.where(reference_name: "sowing").where("started_at < ?", Date.civil(year, 7, 1)).order("stopped_at DESC").first
            if culture = sowing.casts.find_by(reference_name: 'culture').actor rescue nil
              Booker.intervene(:grains_harvest, year, 7, 1, 3.13 * coeff, support: support) do |i|
                i.add_cast(reference_name: 'cropper',        actor: i.find(Product, can: "harvest(poaceae)"))
                i.add_cast(reference_name: 'cropper_driver', actor: i.find(Worker))
                i.add_cast(reference_name: 'culture',        actor: culture)
                i.add_cast(reference_name: 'grains',         population: 4.2 * coeff, variant: ProductNatureVariant.find_or_import!(:grain, derivative_of: culture.variety).first)
                i.add_cast(reference_name: 'straws',         population: 1.5 * coeff, variant: ProductNatureVariant.find_or_import!(:straw, derivative_of: culture.variety).first)
              end
            end
          end
          w.check_point
        end
      end
    end
  end

  Ekylibre::fixturize :animal_interventions do |w|
    for production in Production.all
      variety = production.variant.variety
      if Nomen::Varieties[variety].self_and_parents.include?(Nomen::Varieties[:bos])
        year = production.campaign.name.to_i
        Booker.production = production
        for support in production.supports
          if support.storage.is_a?(AnimalGroup)
            for animal in support.storage.members_at()
              Booker.intervene(:animal_treatment, year - 1, 9, 15, 0.5) do |i|
                i.add_cast(reference_name: 'animal',           actor: animal)
                i.add_cast(reference_name: 'caregiver',        actor: i.find(Worker))
                i.add_cast(reference_name: 'molecule',         actor: i.find(AnimalMedicine, can: "care(bos)"))
                i.add_cast(reference_name: 'molecule_to_give', population: 1 + rand(3))
              end
            end
            w.check_point
          end
        end
      end
    end
  end

end
