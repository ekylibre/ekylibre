# frozen_string_literal: true

module Variant
  class TypeAllocatorService

    attr_reader :category, :nature

    VARIETIES_SUB_NATURES = {
      fertilizer: %w[compost guano liquid_slurry manure slurry],
      seed_and_plant: %w[seed seedling]
    }.freeze

    def initialize(category: nil, nature:)
      @category = category
      @nature = nature
    end

    def find_type
      find_type_from_category || find_type_from_category_and_nature || find_type_from_nature
    end

    private

      def find_type_from_category
        return if category.blank?

        if category.article?
          case category.reference_name
          when 'fertilizer'
            return 'Variants::Articles::FertilizerArticle'
          when 'seed' || 'plant'
            return 'Variants::Articles::SeedAndPlantArticle'
          when 'plant_medicine'
            return 'Variants::Articles::PlantMedicineArticle'
          end

          case category.charge_account&.usages
          when 'fertilizer_expenses'
            'Variants::Articles::FertilizerArticle'
          when 'seed_expenses'
            'Variants::Articles::SeedAndPlantArticle'
          when 'plant_medicine_matter_expenses'
            'Variants::Articles::PlantMedicineArticle'
          end
        end
      end

      def find_type_from_category_and_nature
        return if nature.blank? || category.blank?

        derivative_of_plant_or_animal = nature.derivative_of &&
                                        ((Onoma::Variety.find(nature.derivative_of) <= Onoma::Variety.find(:plant)) ||
                                        (Onoma::Variety.find(nature.derivative_of) <= Onoma::Variety.find(:animal)))

        if nature.article? && category.article? && category.saleable && derivative_of_plant_or_animal
          'Variants::Articles::FarmProductArticle'
        end
      end

      def find_type_from_nature
        return if nature.blank?

        if nature.article? && sub_nature = VARIETIES_SUB_NATURES.detect { |_k, v| v.include? nature.variety }
          "Variants::Articles::#{sub_nature.first.to_s.classify}Article"
        elsif nature.equipment? && nature.of_variety?(:trailed_equipment)
          'Variants::Equipments::TrailedEquipmentEquipment'
        elsif nature.equipment? && nature.of_variety?(:portable_equipment)
          'Variants::Equipments::ToolEquipment'
        elsif nature.equipment? && Onoma::Variety.find(nature.variety) <= Onoma::Variety.find(:motorized_vehicle)
          'Variants::Equipments::MotorizedEquipmentEquipment'
        else
          "Variants::#{nature.type.split('::').last.gsub(/Type/, 'Variant')}"
        end
      end
  end
end
