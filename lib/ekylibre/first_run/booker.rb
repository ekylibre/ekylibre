module Ekylibre
  module FirstRun

    class Booker

      cattr_accessor :production

      class << self

        def find(model, options = {})
          relation = model
          relation = relation.where("COALESCE(born_at, ?) <= ? ", options[:started_at], options[:started_at]) if options[:started_at]
          relation = relation.of_work_numbers(options[:work_number]) if options[:work_number]
          relation = relation.can(options[:can]) if options[:can]
          relation = relation.of_variety(options[:variety]) if options[:variety]
          relation = relation.derivative_of(options[:derivative_of]) if options[:derivative_of]
          if relation.any?
            return relation.all.sample
          else
            # Create product with given elements
            attributes = {}
            unless options[:default_storage].is_a?(FalseClass)
              attributes[:default_storage] = find(BuildingDivision, default_storage: find(Building, default_storage: false))
            end
            if model == Worker
              options[:first_name] ||= Faker::Name.first_name
              options[:last_name]  ||= Faker::Name.last_name
              options[:born_at]    ||= Date.new(1970 + rand(20), 1 + rand(12), 1 + rand(28))
              unless person = Person.find_by(first_name: options[:first_name], last_name: options[:last_name])
                person = Person.create!(first_name: options[:first_name], last_name: options[:last_name], born_at: options[:born_at])
              end
              attributes[:person] = person
            end
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
        def intervene(procedure_code, year, month, day, duration, options = {}, &block)
          day_range = options[:range] || 30

          duration += 1.5 - rand(0.5)

          # Find procedure
          procedure_name = "#{options[:namespace] || Procedo::DEFAULT_NAMESPACE}#{Procedo::NAMESPACE_SEPARATOR}#{procedure_code}#{Procedo::VERSION_SEPARATOR}#{options[:version] || '0'}"
          unless procedure = Procedo[procedure_name]
            raise ArgumentError, "Unknown procedure #{procedure_code} (#{procedure_name})"
          end

          # Find actors
          booker = new(procedure, Time.new(year, month, day), duration)
          yield booker
          actors = booker.casts.collect{|c| c[:actor]}.compact
          if actors.empty?
            raise ArgumentError, "What's the fuck ? No actors ? "
          end

          # Adds fixed durations to given time
          fixed_duration = procedure.fixed_duration / 3600
          duration += fixed_duration

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
          total = duration * 1.0 - fixed_duration
          duration_days.times do
            started_at = on.to_time + self.sunrise(on).hours + 1.hour
            d = self.daytime_duration(on) - 2.0 - fixed_duration
            d = total if d > total
            periods << {started_at: started_at, duration: (d + fixed_duration) * 3600} if d > 0
            total -= d
            on += 1
          end

          # Run interventions
          intervention = nil
          for period in periods
            stopped_at = period[:started_at] + period[:duration]
            if stopped_at < Time.now
              intervention = Intervention.create!(reference_name: procedure_name, production: Booker.production, production_support: options[:support], started_at: period[:started_at], stopped_at: stopped_at)
              for cast in booker.casts
                intervention.add_cast!(cast)
              end
              intervention.run!(period, options[:parameters])
            end
          end
          return intervention
        end
        
        # used for importing intervention from others editors
        # procedure_code symbol (from procedure)
        # started_at datetime
        # duration integer (hours)
        def force(procedure_code, started_at, duration, options = {}, &block)
          
          # Find procedure
          procedure_name = "#{options[:namespace] || Procedo::DEFAULT_NAMESPACE}#{Procedo::NAMESPACE_SEPARATOR}#{procedure_code}#{Procedo::VERSION_SEPARATOR}#{options[:version] || '0'}"
          unless procedure = Procedo[procedure_name]
            raise ArgumentError, "Unknown procedure #{procedure_code} (#{procedure_name})"
          end
          
          # Adds fixed durations to given time
          fixed_duration = procedure.fixed_duration / 3600
          duration += fixed_duration
          
          # Find actors
          booker = new(procedure, started_at, duration)
          yield booker
          actors = booker.casts.collect{|c| c[:actor]}.compact
          if actors.empty?
            raise ArgumentError, "What's the fuck ? No actors ? "
          end
          
          # Find a slot for all actors for given day and given duration
          at = nil
          9.times do |p|
            at = started_at + p
            break unless InterventionCast.joins(:intervention).where(actor_id: actors.map(&:id)).where("? BETWEEN started_at AND stopped_at OR ? BETWEEN started_at AND stopped_at", at, at + duration.hours).any?
          end
          
          # Run interventions
          intervention = nil
            stopped_at = at + duration.hours
            if stopped_at < Time.now    
              intervention = Intervention.create!(reference_name: procedure_name, production: Booker.production, production_support: options[:support], started_at: at, stopped_at: stopped_at)
              for cast in booker.casts
                intervention.add_cast!(cast)
              end
              intervention.run!({started_at: at, duration: duration.hours}, options[:parameters])
            end
          return intervention
        end

      end

      attr_reader :casts, :duration, :started_at, :reference

      def initialize(reference, started_at, duration)
        @reference = reference
        @duration = duration
        @started_at = started_at
        @casts = []
      end

      def add_cast(options = {})
        unless reference.variables[options[:reference_name]]
          raise "Invalid variable: #{options[:reference_name]} in procedure #{reference.name}"
        end
        @casts << options
      end

      # Find a valid actor in the given period
      def find(model, options = {})
        options.update(started_at: @started_at)
        options.update(stopped_at: @started_at)
        self.class.find(model, options)
      end

    end
  end
end
