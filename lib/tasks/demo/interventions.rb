# -*- coding: utf-8 -*-
demo :interventions do

  class Booker

    cattr_accessor :production

    def self.daytime_duration(on)
      12.0 - 4.0 * Math.cos((on + 11.days).yday.to_f / (365.25 / Math::PI / 2))
    end

    def self.sunrise(on, shift = 1.5)
      return shift + (24.0 - self.daytime_duration(on)) / 2.0
    end

    def self.sunset(on, shift = 1.5)
      self.daytime_duration(on) + self.sunrise(on, shift)
    end


    def self.intervene(procedure, year, month, day, duration, options = {}, &block)
      day_range = options[:range] || 30

      # Find actors
      booker = new(duration)
      yield booker
      actors = booker.casts.collect{|c| c[:actor]}.compact
      if actors.empty?
        raise ArgumentError.new("What's the fuck ? No actors ? ")
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
      end while InterventionCast.joins(:intervention).where(actor_id: actors.map(&:id)).where("? BETWEEN started_at AND stopped_at OR ? BETWEEN started_at AND stopped_at", on, on + duration_days).count > 0

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
      int = nil
      for period in periods
        int = Intervention.run!({reference_name: procedure_name, production: Booker.production, production_support: options[:support], started_at: period[:started_at], stopped_at: (period[:started_at] + period[:duration])}, period, &block)
      end
      return int
    end

    attr_reader :casts, :duration

    def initialize(duration)
      @duration = duration
      @casts = []
    end

    def add_cast(options = {})
      @casts << options
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
              i.add_cast(reference_name: 'driver',  actor: Worker.all.sample)
              i.add_cast(reference_name: 'tractor', actor: Product.can("tow(plower)").all.sample)
              i.add_cast(reference_name: 'plow',    actor: Product.can("plow").all.sample)
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
            end

            # Sowing 15-10-N -> 30-10-N
            int = Booker.intervene(:sowing, year - 1, 10, 15, 6.92 * coeff, :range => 15, support: support) do |i|
              i.add_cast(reference_name: 'seeds',       actor: Product.of_variety("seed").derivative_of(variety).all.sample)
              i.add_cast(reference_name: 'seeds_to_sow', quantity: 20)
              i.add_cast(reference_name: 'sower',       actor: Product.can("sow").all.sample)
              i.add_cast(reference_name: 'driver',      actor: Worker.all.sample)
              i.add_cast(reference_name: 'tractor',     actor: Product.can("tow(sower)").all.sample)
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
              i.add_cast(reference_name: 'culture',     variant: ProductNatureVariant.find_or_import!(variety).first, quantity: (area.to_s.to_f / 10000.0))
            end

            culture = int.casts.find_by(reference_name: 'culture').actor rescue nil

            # Fertilizing  01-03-M -> 31-03-M
            fertilizer = Product.of_variety(:mineral_matter).all.sample
            Booker.intervene(:mineral_fertilizing, year, 3, 1, 0.96 * coeff, support: support) do |i|
              i.add_cast(reference_name: 'fertilizer', actor: fertilizer)
              i.add_cast(reference_name: 'fertilizer_to_spread', actor: fertilizer, quantity: 0.4 + rand(0.6))
              i.add_cast(reference_name: 'spreader', actor: Product.can("spread(mineral_matter)").all.sample)
              i.add_cast(reference_name: 'driver', actor: Worker.all.sample)
              i.add_cast(reference_name: 'tractor', actor: Product.can("tow(spreader)").all.sample)
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
            end

            # Organic Fertilizing  01-03-M -> 31-03-M
            organic_fertilizer = Product.of_variety(:manure).derivative_of(:bos).all.sample
            Booker.intervene(:organic_fertilizing, year, 3, 1, 0.96 * coeff, support: support) do |i|
              i.add_cast(reference_name: 'manure',      actor: organic_fertilizer)
              i.add_cast(reference_name: 'manure_to_spread', actor: organic_fertilizer, quantity: 1.2)
              i.add_cast(reference_name: 'spreader',    actor: Product.can("spread(organic_matter)").all.sample)
              i.add_cast(reference_name: 'driver',      actor: Worker.all.sample)
              i.add_cast(reference_name: 'tractor',     actor: Product.can("tow(spreader)").all.sample)
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
            end

            if w.count.modulo(3).zero? # AND NOT prairie
              # Treatment herbicide 01-04 30-04
              molecule = Product.can("kill(plant)").all.sample
              Booker.intervene(:chemical_treatment, year, 4, 1, 1.07 * coeff, support: support) do |i|
                i.add_cast(reference_name: 'molecule', actor: molecule)
                i.add_cast(reference_name: 'molecule_to_spray', actor: molecule, quantity: rand(15))
                i.add_cast(reference_name: 'sprayer',  actor: Product.can("spray").all.sample)
                i.add_cast(reference_name: 'driver',   actor: Worker.all.sample)
                i.add_cast(reference_name: 'tractor',  actor: Product.can("catch").all.sample)
                i.add_cast(reference_name: 'culture',  actor: culture)
              end
            end

          end
          w.check_point
        end
      end
    end
  end

  # result = RubyProf.stop
  # # # Print a graph profile to text
  # # printer = RubyProf::FlatPrinter.new(result)
  # # File.open(Rails.root.join("prof.html"), "wb") do |f|
  # #   printer.print(f, {})
  # # end

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

            bob = Worker.all.sample
            sowing = support.interventions.where(reference_name: "sowing").where("started_at < ?", Date.civil(year, 6, 6)).order("stopped_at DESC").first
            if culture = sowing.casts.find_by(reference_name: 'culture').actor rescue nil
              int = Booker.intervene(:plant_mowing, year, 6, 6, 2.8 * coeff, support: support) do |i|
                i.add_cast(reference_name: 'mower_driver', actor: bob)
                i.add_cast(reference_name: 'tractor',      actor: Product.can("tow(mower)").all.sample)
                i.add_cast(reference_name: 'mower',        actor: Product.can("mow").all.sample)
                i.add_cast(reference_name: 'culture',      actor: culture)
                i.add_cast(reference_name: 'straw', quantity: 1.5 * coeff, variant: ProductNatureVariant.find_or_import!(:straw, derivative_of: culture.variety).first)
              end

              other = Worker.where("id != ?", bob.id).all.sample
              straw = int.casts.find_by_reference_name('straw').actor
              Booker.intervene(:straw_bunching, year, 6, 20, 3.13 * coeff, support: support) do |i|
                i.add_cast(reference_name: 'tractor',        actor: Product.can("tow(baler)").all.sample)
                i.add_cast(reference_name: 'baler_driver',   actor: bob)
                i.add_cast(reference_name: 'baler',          actor: Product.can("bunch").all.sample)
                i.add_cast(reference_name: 'straw_to_bunch', actor: straw)
                i.add_cast(reference_name: 'straw_bales', quantity: 1.5 * coeff, variant: ProductNatureVariant.import_from_nomenclature(culture.variety.to_s == 'triticum_durum' ? :hard_wheat_straw_bales : :wheat_straw_bales))
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
            bob = Worker.all.sample
            other = Worker.where("id != ?", bob.id).all.sample
            sowing = support.interventions.where(reference_name: "sowing").where("started_at < ?", Date.civil(year, 7, 1)).order("stopped_at DESC").first
            if culture = sowing.casts.find_by(reference_name: 'culture').actor rescue nil
              Booker.intervene(:grains_harvest, year, 7, 1, 3.13 * coeff, support: support) do |i|
                # i.add_cast(reference_name: 'silo',    actor: Product.can("store(grain)").all.sample)
                # i.add_cast(reference_name: 'driver',  actor: bob, quantity: i.duration.to_f)
                # i.add_cast(reference_name: 'tractor', actor: Product.can("tow(trailer)").all.sample, quantity: i.duration.to_f)
                # i.add_cast(reference_name: 'trailer', actor: Product.can("store(grain)").all.sample, quantity: i.duration.to_f)
                i.add_cast(reference_name: 'cropper',        actor: Product.can("harvest(poaceae)").all.sample)
                i.add_cast(reference_name: 'cropper_driver', actor: other)
                i.add_cast(reference_name: 'culture',        actor: culture)
                i.add_cast(reference_name: 'grains',         quantity: 4.2 * coeff, variant: ProductNatureVariant.find_or_import!(:grain, derivative_of: culture.variety).first)
                i.add_cast(reference_name: 'straws',         quantity: 1.5 * coeff, variant: ProductNatureVariant.find_or_import!(:straw, derivative_of: culture.variety).first)
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
              medicine_product = AnimalMedicine.can("care(bos)").all.sample
              Booker.intervene(:animal_treatment, year - 1, 9, 15, 0.5) do |i|
                i.add_cast(reference_name: 'animal',           actor: animal)
                i.add_cast(reference_name: 'caregiver',        actor: Worker.all.sample, quantity: 0.2)
                i.add_cast(reference_name: 'molecule',         actor: medicine_product)
                i.add_cast(reference_name: 'molecule_to_give', actor: medicine_product, quantity: 1 + rand(3))
              end
            end
            w.check_point
          end
        end
      end
    end
  end

end
