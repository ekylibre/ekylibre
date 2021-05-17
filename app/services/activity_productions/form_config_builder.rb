# frozen_string_literal: true

module ActivityProductions
  class FormConfigBuilder
    def initialize(activity_production)
      @activity_production = activity_production
      @activity = activity_production.activity
    end

    def self.build(activity_production)
      new(activity_production).build
    end

    def build
      {
        production_nature_specie_scope: production_nature_specie_scope,
        starting_year_collection: starting_year_collection,
        usage_collection: usage_collection,
        support_nature_collection: support_nature_collection
      }
    end

    private

      attr_reader :activity_production, :activity

      def production_nature_specie_scope
        return unless activity.plant_farming? || activity.vine_farming?

        if activity.production_nature.present?
          specie = activity.production_nature.specie
          species = Onoma::Variety.find(specie).children(recursively: true).map(&:name).push(specie)
        else
          specie = Onoma::Variety.find(activity.cultivation_variety)
          species = specie.children(recursively: true).map(&:name).push(specie.name)
        end

        production_natures = MasterProductionNature.of_species(species)
        while production_natures.count == 0
          specie = specie.parent
          species = specie.children(recursively: true).map(&:name).push(specie.name)
          production_natures = MasterProductionNature.of_species(species)
        end

        species
      end

      def starting_year_collection
        initial_starting_year = activity_production.started_on.year
        (initial_starting_year..( initial_starting_year +15)).to_a
      end

      def usage_collection
        if activity.animal_farming?
          Onoma::ProductionUsage.list.select{|usage| %w[meat milk].include?(usage.name)}.selection
        else
          Onoma::ProductionUsage.list.reject{|usage| %w[meat milk].include?(usage.name)}.selection
        end
      end

      def support_nature_collection
        Onoma::ProductionSupportNature.list.select do |nature|
          nature.activity_families.include?(activity.family.to_sym)
        end.selection
      end
  end
end
