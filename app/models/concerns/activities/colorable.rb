# frozen_string_literal: true

module Activities
  module Colorable
    extend ActiveSupport::Concern

    COLORS_INDEX = Rails.root.join('db', 'nomenclatures', 'colors.yml').freeze
    COLORS = (COLORS_INDEX.exist? ? YAML.load_file(COLORS_INDEX) : {}).freeze

    class_methods do
      def color(family, variety)
        activity_family = Onoma::ActivityFamily.find(family)
        variety = Onoma::Variety.find(variety)
        return 'White' unless activity_family

        if activity_family <= :plant_farming || activity_family <= :vine_farming
          list = COLORS['varieties']
          return 'Gray' unless list

          variety.rise { |i| list[i.name] } unless variety.nil?
        elsif activity_family <= :animal_farming
          'Brown'
        elsif activity_family <= :administering
          'RoyalBlue'
        elsif activity_family <= :tool_maintaining
          'SlateGray'
        else
          'DarkGray'
        end
      end
    end
  end
end
